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

require 'date'
require 'nokogiri'
require 'open-uri'

require 'unclekryon/iso'
require 'unclekryon/log'
require 'unclekryon/trainer'
require 'unclekryon/util'

require 'unclekryon/data/album_data'
require 'unclekryon/data/artist_data_data'
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
    attr_reader   :updated_on
    attr_accessor :url
    
    alias_method :training?,:training
    
    def initialize(title=nil,url=nil,artist=ArtistDataData.new(),training: false,train_filepath: nil,
          updated_on: nil,**options)
      @artist = artist
      @exclude_album = false
      @title = title
      @trainers = Trainers.new(train_filepath)
      @training = training
      @updated_on = Util.format_datetime(DateTime.now()) if Util.empty_s?(updated_on)
      @url = Util.empty_s?(url) ? self.class.get_kryon_year_url(title) : url
    end
    
    def self.parse_kryon_date(date,year=nil)
      # Don't modify args and clean them up so can use /\s/ instead of /[[:space:]]/
      date = Util.clean_data(date.clone())
      year = Util.clean_data(year.clone())
      
      # Fix misspellings and/or weird shortenings
      date.gsub!(/Feburary/i,'February') # "Feburary 2-13, 2017"
      date.gsub!(/SEPT\s+/i,'Sep ') # "SEPT 29 - OCT 9, 2017"
      date.gsub!(/Septembe\s+/i,'September ') # "Septembe 4, 2016"
      
      comma = date.include?(',') ? ',' : '' # "May 6 2017"
      r = Array.new(2)
      
      begin
        if date.include?('-')
          # "SEPT 29 - OCT 9, 2017"
          if date =~ /\A[[:alpha:]]+\s+[[:digit:]]+\s+\-\s+[[:alpha:]]+\s+[[:digit:]]+/
            r1f = "%B %d - %B %d#{comma} %Y"
          else
            # "OCT 27 - 28 - 29, 2017"; remove spaces around dashes
            date.gsub!(/\s+\-\s+/,'-')
            
            # "June 7-9-16-17" & "June 9-10-11-12"
            if date =~ /\A[[:alpha:]]+\s*[[:digit:]]+\-[[:digit:]]+\-[[:digit:]]+\-[[:digit:]]+\z/
              r1f = "%B %d-%d-%d-%d"
              
              if !year.nil?()
                date << ", #{year}"
                r1f << ", %Y"
              end
            else
              # "MAY 15-16-17, 2017" and "January 7-8, 2017"
              r1f = (date =~ /\-.*\-/) ? "%B %d-%d-%d#{comma} %Y" : "%B %d-%d#{comma} %Y"
            end
          end
          
          r[1] = Date.strptime(date,r1f)
          r[0] = Date.strptime(date,'%B %d')
          r[0] = Date.new(r[1].year,r[0].month,r[0].day)
        elsif date.include?('/')
          # "JULY/AUG 2017"
          r[1] = Date.strptime(date,'%b/%b %Y')
          r[0] = Date.strptime(date,'%b')
          r[0] = Date.new(r[1].year,r[0].month,r[0].day)
        else
          r[0] = Date.strptime(date,"%B %d#{comma} %Y")
          r[1] = nil
        end
      rescue ArgumentError => e
        Log.instance.fatal("Invalid Date: '#{date}'",e)
        raise
      end
      
      r[0] = (!r[0].nil?) ? Util.format_date(r[0]) : ''
      r[1] = (!r[1].nil?) ? Util.format_date(r[1]) : ''
      
      return r
    end
    
    def parse_site(title=nil,url=nil,artist=nil)
      @artist = artist unless artist.nil?()
      @title = title unless title.nil?()
      
      @url = Util.empty_s?(url) ? self.class.get_kryon_year_url(@title) : url
      
      raise ArgumentError,"Artist cannot be nil" if @artist.nil?()
      raise ArgumentError,"Title cannot be empty" if @title.nil?() || (@title = @title.strip()).empty?()
      raise ArgumentError,"URL cannot be empty" if @url.nil?() || (@url = @url.strip()).empty?()
      
      @release = @artist.releases[@title]
      @trainers.load_file()
      
      if @release.nil?
        @release = ReleaseData.new
        @release.title = @title
        @release.updated_on = @updated_on
        @release.url = @url
        
        @artist.releases[@title] = @release
      end
      
      doc = Nokogiri::HTML(open(@release.url),nil,'utf-8') # Force utf-8 encoding
      row_pos = 1
      rows = doc.css('table tr tr')
      
      rows.each() do |row|
        next if row.nil?
        next if (cells = row.css('td')).nil?
        
        album = AlbumData.new
        album.updated_on = @updated_on
        @exclude_album = false
        
        # There is always a date cell
        has_date_cell = parse_date_cell(cells,album)
        
        # Sometimes there is not a topic, location, or language cell, but not all 3!
        # - Put || last because of short-circuit ||!
        # - For some reason, "or" does not work (even though it is supposed to be non-short-circuit)
        has_other_cell = parse_topic_cell(cells,album)
        has_other_cell = parse_location_cell(cells,album) || has_other_cell
        has_other_cell = parse_language_cell(cells,album) || has_other_cell
        
        if !has_date_cell || !has_other_cell || @exclude_album
          # - If it doesn't have any cells, it is probably javascript or something else, so don't log it
          # - If @exclude_album, then it has already been logged, so don't log it
          if (!has_date_cell && has_other_cell) || (has_date_cell && !@exclude_album)
            log.warn("Excluding album: #{row_pos},#{album.date_begin},#{album.date_end},#{album.title}," <<
              "#{album.locations},#{album.languages}")
            row_pos += 1
          end
          
          next
        end
        
        # Is it actually old or new?
        if @artist.albums.key?(album.url) && album == @artist.albums[album.url]
          album.updated_on = @artist.albums[album.url].updated_on
        end
        
        @artist.albums[album.url] = album
        
        if !@release.albums.include?(album.url)
          @release.albums.push(album.url)
          @release.updated_on = @updated_on
        end
        
        row_pos += 1
      end
      
      return @release
    end
    
    def parse_date_cell(cells,album)
      # Get url from date because sometimes there is not a topic
      
      return false if cells.length <= 1
      return false if (cell = cells[1]).nil?
      return false if (cell = cell.css('a')).nil?
      return false if cell.length < 1
      return false if (cell = cell.first).nil?
      return false if cell.content.nil?
      return false if cell['href'].nil?
      
      r_date = self.class.parse_kryon_date(Util.clean_data(cell.content),@title)
      album.date_begin = r_date[0]
      album.date_end = r_date[1]
      album.url = Util.clean_link(@release.url,cell['href'])
      
      return false if (album.date_begin.empty? || album.url.empty?)
      return true
    end
    
    def parse_language_cell(cells,album)
      return false if cells.length <= 4
      return false if (cell = cells[4]).nil?
      return false if (cell = cell.content).nil?
      
      cell = Util.clean_data(cell)
      # For the official site, they always have English, so add it if not present
      album.languages = Iso.languages.find_by_kryon(cell,add_english: true)
      
      return false if album.languages.nil?() || album.languages.empty?()
      return true
    end
    
    def parse_location_cell(cells,album)
      return false if cells.length <= 3
      return false if (cell = cells[3]).nil?
      return false if (cell = cell.content).nil?
      
      album.locations = Iso.find_kryon_locations(cell)
      
      return false if album.locations.nil?() || album.locations.empty?()
      
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
      return false if cell.content.nil?
      
      album.title = Util.fix_shortwith_text(Util.clean_data(cell.content))
      
      exclude_topics = /
        GROUP[[:space:]]+PHOTO|
        PLEASE[[:space:]]+READ
      /ix
      
      if album.title =~ exclude_topics
        log.warn("Excluding album: Topic[#{album.title}]")
        @exclude_album = true
        return false
      end
      
      # See 2016 'Las Vegas, NV - "Numerology" - (3)' where the date cell's href is an image
      good_urls = /
        \.html?[[:space:]]*\z
      /ix
      
      if album.url !~ good_urls
        bad_url = album.url
        album.url = Util.clean_link(@release.url,cell['href'])
        log.warn("Using topic cell's href for URL: #{File.basename(bad_url)}=>#{File.basename(album.url)}")
        
        if Util.empty_s?(album.url)
          msg = "Date and topic cells' hrefs are empty: Topic[#{album.title}]"
          
          if DevOpts.instance.dev?()
            raise msg
          else
            log.warn(msg)
          end
          
          return false
        end
      end
      
      return false if album.title.empty?
      return true
    end
    
    def self.get_kryon_year_url(year)
      if year == '2002-2005'
        url = 'http://www.kryon.com/freeAudio_folder/2002_05_freeAudio.html'
      else
        url = "http://www.kryon.com/freeAudio_folder/#{year}_freeAudio.html"
      end
      
      return url
    end
  end
end
