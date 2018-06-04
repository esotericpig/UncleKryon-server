#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2018 Jonathan Bradley Whited (@esotericpig)
# 
# UncleKryon-server is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# UncleKryon-server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with UncleKryon-server.  If not, see <http://www.gnu.org/licenses/>.
###

require 'nokogiri'
require 'open-uri'

require 'unclekryon/iso'
require 'unclekryon/log'
require 'unclekryon/trainer'
require 'unclekryon/util'

require 'unclekryon/data/artist_data'
require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/release_data'

module UncleKryon
  class KryonAumYearParser
    include Logging
    
    attr_accessor :artist
    attr_accessor :exclude_album
    attr_accessor :release
    attr_accessor :title
    attr_accessor :trainers
    attr_accessor :training
    attr_accessor :url
    
    alias_method :training?,:training
    
    def initialize(title=nil,url=nil,artist=ArtistData.new(),training: false,train_filepath: nil,**options)
      @artist = artist
      @exclude_album = false
      @title = title
      @trainers = Trainers.new(train_filepath)
      @training = training
      @url = url
      
      # Not used anymore
      #@trainers['aum_year_topic'] = Trainer.new({
      #    't'=>'Topic',
      #    'i'=>'Ignore',
      #    'us'=>'USA'
      #    'no'=>'Non-USA'
      #  })
    end
    
    def parse_site(title=nil,url=nil,artist=nil)
      @artist = artist unless artist.nil?()
      @title = title unless title.nil?()
      @url = url unless url.nil?()
      
      @release = @artist.releases[@title]
      @trainers.load_file()
      
      raise ArgumentError,"Artist cannot be nil" if @artist.nil?()
      raise ArgumentError,"Title cannot be empty" if @title.nil?() || (@title = @title.strip()).empty?()
      raise ArgumentError,"URL cannot be empty" if @url.nil?() || (@url = @url.strip()).empty?()
      
      if @release.nil?
        @release = ReleaseData.new
        @release.title = @title
        @release.url = @url
        @artist.releases[@title] = @release
      end
      
      doc = Nokogiri::HTML(open(@release.url),nil,'utf-8') # Force utf-8 encoding
      rows = doc.css('table tr tr')
      
      rows.each do |row|
        next if row.nil?
        next if (cells = row.css('td')).nil?
        
        album = KryonAumAlbumData.new
        @exclude_album = false
        
        # There is always a year cell
        next if !parse_year_cell(cells,album)
        
        # Sometimes there is not a topic, location, or language cell, but not all 3!
        # - Put next_row last because of short-circuit &&!
        # - For some reason, "and" does not work (even though it is supposed to be non-short-circuit)
        next_row = !parse_topic_cell(cells,album)
        next_row = !parse_location_cell(cells,album) && next_row
        next_row = !parse_language_cell(cells,album) && next_row
        
        next if @exclude_album || next_row
        
        album.fill_empty_data()
        @artist.albums[album.id] = album
        @release.album_ids.push(album.id) if !@release.album_ids.include?(album.id)
      end
      
      return @release
    end
    
    def parse_year_cell(cells,album)
      # Get url from date because sometimes there is not a topic
      
      return false if cells.length <= 1
      return false if (cell = cells[1]).nil?
      return false if (cell = cell.css('a')).nil?
      return false if cell.length < 1
      return false if (cell = cell.first).nil?
      return false if cell.content.nil?
      return false if cell['href'].nil?
      
      r_year = Util.parse_kryon_date(Util.clean_data(cell.content))
      album.r_year_begin = r_year[0]
      album.r_year_end = r_year[1]
      album.url = Util.clean_link(@release.url,cell['href'])
      
      return false if (album.r_year_begin.empty? || album.url.empty?)
      
      album.id = Util.gen_id(album.url)
      
      return true
    end
    
    def parse_language_cell(cells,album)
      return false if cells.length <= 4
      return false if (cell = cells[4]).nil?
      return false if (cell = cell.content).nil?
      
      cell = Util.clean_data(cell)
      # For the official site, they always have English, so add it if not present
      album.r_language = Iso.languages.find_by_kryon(cell,add_english: true)
      
      return false if album.r_language.nil?()
      return true
    end
    
    def parse_location_cell(cells,album)
      return false if cells.length <= 3
      return false if (cell = cells[3]).nil?
      return false if (cell = cell.content).nil?
      
      album.r_location = Iso.find_kryon_locations(cell)
      
      return false if album.r_location.nil?()
      
      # Not used anymore
      #album.r_location.each_with_index() do |l,i|
      #  if @training
      #    @trainers['aum_year'].train(l)
      #  else
      #    case @trainers['aum_year'].tag(l)
      #    when 'USA'
      #      album.r_location[i] << ', USA'
      #    end
      #  end
      #end
      
      return true
    end
    
    def parse_topic_cell(cells,album)
      return false if cells.length <= 2
      return false if (cell = cells[2]).nil?
      return false if (cell = cell.css('a')).nil?
      return false if cell.length < 1
      
      # For 2017 "San Jose, California (3)"
      cell = (cell.length <= 1) ? cell.first : cell.pop
      
      return false if cell.nil?
      return false if (cell = cell.content).nil?
      
      album.r_topic = Util.fix_shortwith_text(Util.clean_data(cell))
      
      exclude_topics = /
        GROUP[[:space:]]+PHOTO|
        PLEASE[[:space:]]+READ
      /ix
      
      if album.r_topic =~ exclude_topics
        log.warn("Excluding topic: #{album.r_topic}")
        @exclude_album = true
        return false
      end
      
      # Not used, as there are just a few exclude cases
      #if @training
      #  @trainers['aum_year_topic'].train(album.r_topic)
      #else
      #  case @trainers['aum_year_topic'].tag(album.r_topic)
      #  when 'Ignore'
      #    return false
      #  end
      #end
      
      return false if album.r_topic.empty?
      return true
    end
  end
end
