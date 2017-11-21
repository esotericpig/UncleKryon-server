#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2017 Jonathan Bradley Whited (@esotericpig)
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

require 'bundler/setup'

require 'date'

require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/artist_data'

require 'unclekryon/parsers/kryon_aum_year_album_parser'
require 'unclekryon/parsers/kryon_aum_year_parser'

module UncleKryon
  class Hacker
    DIRNAME = 'yaml'
    KRYON_FILENAME = 'kryon.yaml'
    
    attr_accessor :dirname
    attr_accessor :kryon_filename
    attr_accessor :no_clobber
    attr_accessor :overwrite
    attr_accessor :replace
    attr_accessor :slow
    
    def initialize()
      @dirname = DIRNAME
      @kryon_filename = KRYON_FILENAME
      @no_clobber = false
      @overwrite = false
      @replace = true
      @slow = true
    end
    
    def parse_kryon_aum_year(year)
      artist = ArtistData.new
      year_parser = KryonAumYearParser.new
      release = year_parser.parse_site(artist,year,Util::get_kryon_year_url(year))
      
      if @no_clobber
        puts release.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=@replace,who=:kryon_aum_year,overwrite=@overwrite)
      end
    end
    
    def parse_kryon_aum_year_album(date,year=nil)
      index = date.split(':')
      date = index[0]
      index = (index.length <= 1) ? 0 : (index[1].to_i() - 1)
      
      begin
        new_date = Date.strptime(date,'%Y.%m.%d')
      rescue ArgumentError
        new_date = Date.strptime(date,'%m.%d')
        
        if !year.nil?
          new_date = Date.new(year.to_i,new_date.month,new_date.day)
        end
      end
      
      date = new_date
      
      if year.nil?
        # #year is actually the release's title, so only override it if have to
        year = date.year.to_s
      end
      
      # Try the yaml file
      artist = Util::load_artist_yaml(get_kryon_filepath())
      release = artist.releases[year]
      
      if release.nil?
        # Try manually from the site
        artist = ArtistData.new
        year_parser = KryonAumYearParser.new
        release = year_parser.parse_site(artist,year,Util::get_kryon_year_url(year))
      end
      
      # Find the album
      albums = []
      album = nil
      
      artist.albums.values.each do |a|
        r_year_begin = Util::parse_date(a.r_year_begin)
        r_year_end = Util::parse_date(a.r_year_end)
        date_begin = Util::parse_date(a.date_begin)
        date_end = Util::parse_date(a.date_end)
        
        if (r_year_begin && ((r_year_end  && date >= r_year_begin && date <= r_year_end) ||
                             (!r_year_end && date == r_year_begin))) ||
           (date_begin && ((date_end  && date >= date_begin && date <= date_end) ||
                           (!date_end && date == date_begin)))
          albums.push(a)
        end
      end
      
      if !albums.empty?
        if index >= 0 && index < albums.length
          album = albums[index]
        else
          raise "Invalid album ordinal number[#{index + 1}]"
        end
      end
      
      if album.nil?
        raise "Invalid album[#{date}]"
      end
      
      album_parser = KryonAumYearAlbumParser.new
      album = album_parser.parse_site(artist,album.url,@slow)
      
      if @no_clobber
        puts album.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=@replace,who=:kryon_aum_year_album,overwrite=@overwrite)
      end
    end
    
    def parse_kryon_aum_year_albums(year)
      # Try the yaml file
      artist = Util::load_artist_yaml(get_kryon_filepath())
      release = artist.releases[year]
      
      if release.nil?
        # Try manually from the site
        artist = ArtistData.new
        year_parser = KryonAumYearParser.new
        release = year_parser.parse_site(artist,year,Util::get_kryon_year_url(year))
      end
      
      album_parser = KryonAumYearAlbumParser.new
      
      release.album_ids.each do |album_id|
        album = artist.albums[album_id]
        Log.instance.log.info("Hacking album[#{album.r_year_begin},#{album.r_year_end},#{album.r_topic}]")
        album = album_parser.parse_site(artist,album.url,@slow)
      end
      
      if @no_clobber
        puts release.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=@replace,who=:kryon_aum_year_album,overwrite=@overwrite)
      end
    end
    
    def get_kryon_filepath()
      return File.join(@dirname,@kryon_filename)
    end
  end
end

if $0 == __FILE__
  hax = UncleKryon::Hacker.new
  #hax.parse_kryon_aum_year('2017')
  #hax.parse_kryon_aum_year_albums('2017')
end
