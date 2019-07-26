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


require 'yaml'

require 'unclekryon/util'

require 'unclekryon/data/base_data'
require 'unclekryon/data/social_data'

module UncleKryon
  class ArtistData < BaseData
    ID = 'Artist'
    
    attr_accessor :updated_releases_on
    attr_accessor :updated_albums_on
    attr_accessor :updated_aums_on
    attr_accessor :updated_scrolls_on
    attr_accessor :updated_visions_on
    attr_accessor :updated_pics_on
    
    attr_accessor :id
    attr_accessor :name
    attr_accessor :long_name
    attr_accessor :desc
    
    attr_accessor :url
    attr_accessor :mirrors
    
    attr_accessor :facebook
    attr_accessor :twitter
    attr_accessor :youtube
    
    def initialize()
      super()
      
      @updated_releases_on = ''
      @updated_albums_on = ''
      @updated_aums_on = ''
      @updated_scrolls_on = ''
      @updated_visions_on = ''
      @updated_pics_on = ''
      
      @id = ''
      @name = ''
      @long_name = ''
      @desc = ''
      
      @url = ''
      @mirrors = {}
      
      @facebook = SocialData.new()
      @twitter = SocialData.new()
      @youtube = SocialData.new()
    end
    
    def self.load_file(filepath)
      y = YAML.load_file(filepath)
      artist = y[ID]
      return artist
    end
    
    def save_to_file(filepath,**options)
      raise "Empty filepath: #{filepath}" if filepath.nil?() || (filepath = filepath.strip()).empty?()
      
      Util.mk_dirs_from_filepath(filepath)
      File.open(filepath,'w') do |f|
        artist = {ID=>self}
        YAML.dump(artist,f)
      end
    end
    
    def to_mini_s()
      return to_s(true)
    end
    
    def to_s(mini=false)
      s = ''
      s << ('%-5s' % [@id])
      s << (' | %15s' % [@name])
      s << (' | %25s' % [@long_name])
      s << (' | %s' % [@desc])
      s << (' | fb: @%-20s' % [@facebook.username])
      s << (' | tw: @%-20s' % [@twitter.username])
      s << (' | yt: @%-35s' % [@youtube.username])
      return s
    end
  end
end
