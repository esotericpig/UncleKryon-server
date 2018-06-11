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

require 'yaml'

require 'unclekryon/util'

require 'unclekryon/data/base_data'
require 'unclekryon/data/social_data'

module UncleKryon
  class ArtistData < BaseData
    DEFAULT_ID = 'Artist'
    
    attr_accessor :updated_aums_on
    
    attr_accessor :id
    attr_accessor :name
    attr_accessor :long_name
    
    attr_accessor :url
    attr_accessor :mirrors
    
    attr_accessor :facebook
    attr_accessor :twitter
    attr_accessor :youtube
    
    def initialize()
      super()
      
      @updated_aums_on = ''
      
      @id = ''
      @name = ''
      @long_name = ''
      
      @url = ''
      @mirrors = {}
      
      @facebook = SocialData.new()
      @twitter = SocialData.new()
      @youtube = SocialData.new()
    end
    
    def self.load_file(filepath)
      y = YAML.load_file(filepath)
      artist = y[DEFAULT_ID]
      return artist
    end
    
    def save_to_file(filepath,**options)
      raise "Empty filepath: #{filepath}" if filepath.nil?() || (filepath = filepath.strip()).empty?()
      
      Util.mk_dirs_from_filepath(filepath)
      File.open(filepath,'w') do |f|
        artist = {DEFAULT_ID=>self}
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
      s << (' | fb: @%-20s' % [@facebook.username])
      s << (' | tw: @%-20s' % [@twitter.username])
      s << (' | yt: @%-35s' % [@youtube.username])
      return s
    end
  end
end
