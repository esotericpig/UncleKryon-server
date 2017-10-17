#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/release_data'
require 'unclekryon/util'

module UncleKryon
  class KryonAumYearParser
    attr_accessor :release
    
    def parse_site(artist,title,url)
      @release = artist.releases[title]
      
      if @release.nil?
        @release = ReleaseData.new
        @release.title = title
        @release.url = url
        artist.releases[@release.title] = @release
      end
      
      doc = Nokogiri::HTML(open(@release.url),nil,'utf-8') # Force utf-8 encoding
      rows = doc.css('table tr tr')
      
      rows.each do |row|
        next if row.nil?
        next if (cells = row.css('td')).nil?
        
        album = KryonAumAlbumData.new
        
        # There is always a year cell
        next if !parse_year_cell(cells,album)
        
        # Sometimes there is not a topic, location, or language cell, but not all 3!
        # - Put next_row last because of short-circuit &&!
        # - For some reason, "and" does not work (even though it is supposed to be non-short-circuit)
        next_row = !parse_topic_cell(cells,album)
        next_row = !parse_location_cell(cells,album) && next_row
        next_row = !parse_language_cell(cells,album) && next_row
        next if next_row
        
        artist.albums[album.id] = album
        @release.album_ids.push(album.id)
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
      
      r_year = Util::parse_kryon_date(Util::clean_data(cell.content))
      album.r_year_begin = r_year[0]
      album.r_year_end = r_year[1]
      album.url = Util::clean_link(@release.url,cell['href'])
      
      return false if (album.r_year_begin.empty? || album.url.empty?)
      
      album.id = Util::gen_id(album.url)
      
      return true
    end
    
    def parse_language_cell(cells,album)
      return false if cells.length <= 4
      return false if (cell = cells[4]).nil?
      return false if (cell = cell.content).nil?
      
      album.r_language = Util::clean_data(cell)
      
      return false if album.r_language.empty?
      return true
    end
    
    def parse_location_cell(cells,album)
      return false if cells.length <= 3
      return false if (cell = cells[3]).nil?
      return false if (cell = cell.content).nil?
      
      album.r_location = Util::clean_data(cell)
      
      return false if album.r_location.empty?
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
      
      album.r_topic = Util::fix_shortwith_text(Util::clean_data(cell))
      
      return false if album.r_topic.empty?
      return true
    end
  end
end
