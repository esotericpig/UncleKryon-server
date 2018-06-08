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

module UncleKryon
  class KryonAumData
    attr_accessor :id
    attr_accessor :title
    attr_accessor :subtitle
    attr_accessor :time
    attr_accessor :size
    attr_accessor :filename
    attr_accessor :url
    attr_accessor :mirrors
    attr_accessor :language
    
    def initialize
      @id = 0
      @title = ''
      @subtitle = ''
      @time = ''
      @size = ''
      @filename = ''
      @url = ''
      @mirrors = {}
      @language = ''
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      return s
    end
  end
end
