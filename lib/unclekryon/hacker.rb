#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2019 Jonathan Bradley Whited (@esotericpig)
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
# along with UncleKryon-server.  If not, see <https://www.gnu.org/licenses/>.
#++


require 'bundler/setup'

require 'date'

require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/artist_data_data'

require 'unclekryon/parsers/kryon_aum_year_album_parser'
require 'unclekryon/parsers/kryon_aum_year_parser'

module UncleKryon
  class Hacker
    include Logging
    
    HAX_DIRNAME = 'hax'
    HAX_KRYON_FILENAME = 'kryon_<hax>_<release>.yaml'
    
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
      artist = ArtistDataData.load_file(get_hax_kryon_aums_filepath(year))
      release = artist.releases[year]
      
      if release.nil?()
        # Try manually from the site
        year_parser = create_kryon_aum_year_parser(year)
        artist = year_parser.artist
        release = year_parser.parse_site()
        raise "Release[#{year}] does not exist" if release.nil?()
      end
      
      album = find_kryon_aum_year_album(artist,date,year,index)[0]
      album_parser = KryonAumYearAlbumParser.new(artist,album.url)
      
      album_parser.album = album
      album_parser.trainers.filepath = get_train_kryon_filepath()
      
      return album_parser
    end
    
    def create_kryon_aum_year_parser(year)
      year_parser = KryonAumYearParser.new(year)
      
      year_parser.trainers.filepath = get_train_kryon_filepath()
      
      return year_parser
    end
    
    def find_kryon_aum_year_album(artist,date,year=nil,index=nil)
      album = nil
      albums = []
      
      artist.albums.values.each_with_index do |a,i|
        date_begin = Util.parse_date_s(a.date_begin)
        date_end = Util.parse_date_s(a.date_end)
        
        if (date_begin && ((date_end  && date >= date_begin && date <= date_end) ||
                           (!date_end && date == date_begin)))
          albums.push([a,i])
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
      
      return album
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
        puts release.to_s()
      else
        year_parser.artist.save_to_file(get_hax_kryon_aums_filepath(year))
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
        puts album_parser.album.to_s()
      else
        album_parser.artist.save_to_file(get_hax_kryon_aums_filepath(year))
      end
    end
    
    def parse_kryon_aum_year_albums(year,begin_album=nil)
      if !begin_album.nil?()
        pd = parse_date(begin_album,year)
        begin_album = pd[:date]
        index = pd[:index]
        year = pd[:year]
      end
      
      # Try the yaml file
      artist = ArtistDataData.load_file(get_hax_kryon_aums_filepath(year))
      release = artist.releases[year]
      updated_on = nil
      
      if release.nil?()
        # Try manually from the site
        year_parser = create_kryon_aum_year_parser(year)
        artist = year_parser.artist
        release = year_parser.parse_site()
        raise "Release[#{year}] does not exist" if release.nil?()
        updated_on = release.updated_on
      end
      
      album_parser = KryonAumYearAlbumParser.new
      album_parser.trainers.filepath = get_train_kryon_filepath()
      album_parser.updated_on = updated_on unless updated_on.nil?()
      
      albums = release.albums
      
      if !begin_album.nil?()
        album_index = find_kryon_aum_year_album(artist,begin_album,year,index)[1]
        albums = albums[album_index..-1]
      end
      
      albums.each do |album_id|
        album = artist.albums[album_id]
        log.info("Hacking album[#{album.date_begin},#{album.date_end},#{album.title}]")
        album = album_parser.parse_site(artist,album.url)
      end
      
      if @no_clobber
        puts release.to_s()
      else
        artist.save_to_file(get_hax_kryon_aums_filepath(year))
      end
    end
    
    def train_kryon_aum_year(year)
      year_parser = create_kryon_aum_year_parser(year)
      year_parser.training = true
      release = year_parser.parse_site()
      
      if @no_clobber
        puts year_parser.trainers.to_s()
      else
        year_parser.trainers.save_to_file()
      end
    end
    
    def train_kryon_aum_year_album(date,year=nil,index=nil)
      album_parser = create_kryon_aum_year_album_parser(date,year,index)
      album_parser.training = true
      album = album_parser.parse_site()
      
      if @no_clobber
        puts album_parser.trainers.to_s()
      else
        album_parser.trainers.save_to_file()
      end
    end
    
    def train_kryon_aum_year_albums(year,begin_album=nil)
      if !begin_album.nil?()
        pd = parse_date(begin_album,year)
        begin_album = pd[:date]
        index = pd[:index]
        year = pd[:year]
      end
      
      # Try the yaml file
      artist = ArtistDataData.load_file(get_hax_kryon_aums_filepath(year))
      release = artist.releases[year]
      
      if release.nil?()
        # Try manually from the site
        year_parser = create_kryon_aum_year_parser(year)
        artist = year_parser.artist
        release = year_parser.parse_site()
        raise "Release[#{year}] does not exist" if release.nil?()
      end
      
      albums = release.albums
      
      if !begin_album.nil?()
        album_index = find_kryon_aum_year_album(artist,begin_album,year,index)[1]
        albums = albums[album_index..-1]
      end
      
      albums.each do |album_id|
        album = artist.albums[album_id]
        
        album_parser = KryonAumYearAlbumParser.new
        album_parser.album = album
        album_parser.trainers.filepath = get_train_kryon_filepath()
        album_parser.training = true
        
        log.info("Training album[#{album.date_begin},#{album.date_end},#{album.title}]")
        album = album_parser.parse_site(artist,album.url)
        
        if @no_clobber
          puts album_parser.trainers.to_s()
        else
          album_parser.trainers.save_to_file()
        end
      end
    end
    
    def get_hax_kryon_aums_filepath(release)
      return get_hax_kryon_filepath('aums',release)
    end
    
    def get_hax_kryon_filepath(hax,release)
      raise "Release (year) arg is nil" if release.nil?()
      
      fn = @hax_kryon_filename.clone()
      fn = fn.gsub('<hax>',hax)
      fn = fn.gsub('<release>',release.to_s())
      
      return File.join(@hax_dirname,fn)
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
