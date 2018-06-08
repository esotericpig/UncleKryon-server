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

require 'yaml'

module UncleKryon
  class KryonAumAlbumData
    # Release's album data
    attr_accessor :r_year_begin
    attr_accessor :r_year_end
    attr_accessor :r_topic
    attr_accessor :r_location
    attr_accessor :r_language
    
    # Non-release album data
    attr_accessor :id
    attr_accessor :url
    attr_accessor :mirrors
    attr_accessor :title
    attr_accessor :date_begin
    attr_accessor :date_end
    attr_accessor :location
    attr_accessor :language
    attr_accessor :mini_desc
    attr_accessor :main_desc
    
    attr_accessor :pic_ids
    attr_accessor :aum_ids
    
    attr_accessor :dump
    
    def initialize
      @r_year_begin = ''
      @r_year_end = ''
      @r_topic = ''
      @r_location = ''
      @r_language = ''
      
      @id = 0
      @url = ''
      @mirrors = {}
      @title = ''
      @date_begin = ''
      @date_end = ''
      @location = ''
      @language = ''
      @mini_desc = ''
      @main_desc = ''
      
      @pic_ids = []
      @aum_ids = []
      
      @dump = nil
    end
    
    def fill_empty_data
      # Clone to avoid yaml pointer/reference syntax; nil has clone
      
      if @title.nil? || @title.empty?
        @title = @r_topic.clone
      end
      if @date_begin.nil? || (@date_begin.respond_to?('empty?') && @date_begin.empty?)
        @date_begin = @r_year_begin.clone
      end
      if @date_end.nil? || (@date_end.respond_to?('empty?') && @date_end.empty?)
        @date_end = @r_year_end.clone
      end
      if @location.nil? || @location.empty?
        @location = @r_location.clone
      end
      if @language.nil? || @language.empty?
        @language = @r_language.clone
      end
    end
    
    def set_nonrelease_data(album)
      @title = album.title
      @date_begin = album.date_begin
      @date_end = album.date_end
      @location = album.location
      @language = album.language
      @mini_desc = album.mini_desc
      @main_desc = album.main_desc
      
      @pic_ids = album.pic_ids
      @aum_ids = album.aum_ids
      
      @dump = album.dump
      
      fill_empty_data()
    end
    
    def set_release_data(album)
      @r_year_begin = album.r_year_begin
      @r_year_end = album.r_year_end
      @r_topic = album.r_topic
      @r_location = album.r_location
      @r_language = album.r_language
      
      fill_empty_data()
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      if !artist.nil?
        @pic_ids.each do |pic_id|
          pic = artist.pics[pic_id]
          s += (!pic.nil?) ? pic.to_s(artist) : "ERROR: #{pic_id} is nil!"
        end
        
        @aum_ids.each do |aum_id|
          aum = artist.aums[aum_id]
          s += (!aum.nil?) ? aum.to_s(artist) : "ERROR: #{aum_id} is nil!"
        end
      end
      
      return s
    end
  end
end
