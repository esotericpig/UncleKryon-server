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
  class ReleaseData
    attr_accessor :title
    attr_accessor :url
    attr_accessor :mirrors
    attr_accessor :album_ids
    
    def initialize
      @title = ''
      @url = ''
      @mirrors = {}
      @album_ids = []
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      if !artist.nil?
        @album_ids.each do |album_id|
          album = artist.albums[album_id]
          s += (!album.nil?) ? album.to_s(artist) : "ERROR: #{album_id} is nil!"
        end
      end
      
      return s
    end
  end
end
