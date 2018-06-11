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

require 'unclekryon/data/base_data'

module UncleKryon
  class KryonAumData < BaseData
    attr_accessor :title
    attr_accessor :subtitle
    attr_accessor :languages
    attr_accessor :timespan
    attr_accessor :filesize
    attr_accessor :filename
    
    attr_accessor :url
    attr_accessor :mirrors
    
    def initialize()
      super()
      
      @title = ''
      @subtitle = ''
      @languages = []
      @timespan = ''
      @filesize = ''
      @filename = ''
      
      @url = ''
      @mirrors = {}
    end
    
    # Excludes @updated_on
    def ==(y)
      return @title == y.title &&
             @subtitle == y.subtitle &&
             @languages == y.languages &&
             @timespan == y.timespan &&
             @filesize == y.filesize &&
             @filename == y.filename &&
             @url == y.url &&
             @mirrors == y.mirrors
    end
    
    def to_s()
      s = ''
      s << ('%-40s' % [@title])
      s << (' | %30s' % [@subtitle])
      s << (' | %10s' % [@languages.join(';')])
      s << (' | %10s' % [@timespan])
      s << (' | %10s' % [@filesize])
      s << (' | %30s' % [@filename])
      return s
    end
  end
end
