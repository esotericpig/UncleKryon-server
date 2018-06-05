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

require 'bundler/setup'

require 'date'

require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/artist_data'

require 'unclekryon/parsers/kryon_aum_year_album_parser'
require 'unclekryon/parsers/kryon_aum_year_parser'

module UncleKryon
  class Hacker
    include Logging
    
    HAX_DIRNAME = 'hax'
    HAX_KRYON_FILENAME = 'kryon_<release>.yaml'
    
    TRAIN_DIRNAME = 'train'
    TRAIN_KRYON_FILENAME = 'kryon.yaml'
    
    attr_accessor :hax_dirname
    attr_accessor :hax_kryon_filename
    attr_accessor :no_clobber
    attr_accessor :train_dirname
    attr_accessor :train_kryon_filename
    
    alias_method :no_clobber?,:no_clobber
    
    def initialize(hax_dirname: HAX_DIRNAME,hax_kryon_filename: HAX_KRYON_FILENAME,no_clobber: false,
          train_dirname: TRAIN_DIRNAME,train_kryon_filename: TRAIN_KRYON_FILENAME,**options)
      @hax_dirname = hax_dirname
      @hax_kryon_filename = hax_kryon_filename
      @no_clobber = no_clobber
      @train_dirname = train_dirname
      @train_kryon_filename = train_kryon_filename
    end
    
    def create_kryon_aum_year_album_parser(date,year=nil,index=nil)
      pd = parse_date(date,year,index)
      date = pd[:date]
      index = pd[:index]
      year = pd[:year]
      
      # Try the yaml file
      artist = Util.load_artist_yaml(get_hax_kryon_filepath(year))
      release = artist.releases[year]
      
      if release.nil?()
        # Try manually from the site
        year_parser = create_kryon_aum_year_parser(year)
        artist = year_parser.artist
        release = year_parser.parse_site()
        raise "Release[#{year}] does not exist" if release.nil?()
      end
      
      # Find the album
      album = nil
      albums = []
      
      artist.albums.values.each do |a|
        r_year_begin = Util.parse_date(a.r_year_begin)
        r_year_end = Util.parse_date(a.r_year_end)
        date_begin = Util.parse_date(a.date_begin)
        date_end = Util.parse_date(a.date_end)
        
        if (r_year_begin && ((r_year_end  && date >= r_year_begin && date <= r_year_end) ||
                             (!r_year_end && date == r_year_begin))) ||
           (date_begin && ((date_end  && date >= date_begin && date <= date_end) ||
                           (!date_end && date == date_begin)))
          albums.push(a)
        end
      end
      
      if !albums.empty?()
        if index >= 0 && index < albums.length
          album = albums[index]
        else
          raise "Invalid album ordinal number[#{index + 1}]"
        end
      end
      
      raise "Invalid album[#{date}]" if album.nil?()
      
      album_parser = KryonAumYearAlbumParser.new(artist,album.url)
      
      album_parser.album = album
      album_parser.trainers.filepath = get_train_kryon_filepath()
      
      return album_parser
    end
    
    def create_kryon_aum_year_parser(year)
      year_parser = KryonAumYearParser.new(year,Util.get_kryon_year_url(year))
      
      year_parser.trainers.filepath = get_train_kryon_filepath()
      
      return year_parser
    end
    
    def parse_date(date,year=nil,index=nil)
      if !date.is_a?(Date)
        ds = date.split(':')
        date = ds[0]
        
        if index.nil?()
          index = ds
          index = (index.length <= 1) ? 0 : (index[1].to_i() - 1)
        end
        
        begin
          new_date = Date.strptime(date,'%Y.%m.%d')
        rescue ArgumentError
          new_date = Date.strptime(date,'%m.%d')
          
          if !year.nil?()
            new_date = Date.new(year.to_i(),new_date.month,new_date.day)
          end
        end
        
        date = new_date
      elsif index.nil?()
        index = 0
      end
      
      if year.nil?()
        # year is actually the release's title, so only override it if have to
        year = date.year.to_s()
      end
      
      return {:date=>date,:index=>index,:year=>year}
    end
    
    def parse_kryon_aum_year(year)
      year_parser = create_kryon_aum_year_parser(year)
      release = year_parser.parse_site()
      
      if @no_clobber
        puts release.to_s(year_parser.artist)
      else
        Util.save_artist_yaml(year_parser.artist,get_hax_kryon_filepath(year))
      end
    end
    
    def parse_kryon_aum_year_album(date,year=nil,index=nil)
      pd = parse_date(date,year,index)
      date = pd[:date]
      index = pd[:index]
      year = pd[:year]
      
      album_parser = create_kryon_aum_year_album_parser(date,year,index)
      album = album_parser.parse_site()
      
      if @no_clobber
        puts album_parser.album.to_s(album_parser.artist)
      else
        Util.save_artist_yaml(album_parser.artist,get_hax_kryon_filepath(year))
      end
    end
    
    def parse_kryon_aum_year_albums(year)
      # Try the yaml file
      artist = Util.load_artist_yaml(get_hax_kryon_filepath(year))
      release = artist.releases[year]
      
      if release.nil?()
        # Try manually from the site
        year_parser = create_kryon_aum_year_parser(year)
        artist = year_parser.artist
        release = year_parser.parse_site()
        raise "Release[#{year}] does not exist" if release.nil?()
      end
      
      album_parser = KryonAumYearAlbumParser.new
      
      release.album_ids.each do |album_id|
        album = artist.albums[album_id]
        log.info("Hacking album[#{album.r_year_begin},#{album.r_year_end},#{album.r_topic}]")
        album = album_parser.parse_site(artist,album.url)
      end
      
      if @no_clobber
        puts release.to_s(artist)
      else
        Util.save_artist_yaml(artist,get_hax_kryon_filepath(year))
      end
    end
    
    def train_kryon_aum_year(year)
      year_parser = create_kryon_aum_year_parser(year)
      year_parser.training = true
      release = year_parser.parse_site()
      
      if @no_clobber
        puts year_parser.trainers.to_s()
      else
        year_parser.trainers.save_file()
      end
    end
    
    def train_kryon_aum_year_album(date,year=nil,index=nil)
      album_parser = create_kryon_aum_year_album_parser(date,year,index)
      album_parser.training = true
      album = album_parser.parse_site()
      
      if @no_clobber
        puts album_parser.trainers.to_s()
      else
        album_parser.trainers.save_file()
      end
    end
    
    def get_hax_kryon_filepath(release)
      raise "Release (year) arg is nil" if release.nil?()
      return File.join(@hax_dirname,@hax_kryon_filename.gsub('<release>',release.to_s()))
    end
    
    def get_train_kryon_filepath()
      return File.join(@train_dirname,@train_kryon_filename)
    end
  end
end

if $0 == __FILE__
  hacker = UncleKryon::Hacker.new(no_clobber: true)
  
  #hacker.parse_kryon_aum_year('2017')
  #hacker.parse_kryon_aum_year_albums('2017')
  hacker.train_kryon_aum_year_album('2.2','2017')
end
