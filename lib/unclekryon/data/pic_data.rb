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


require 'unclekryon/data/base_data'

module UncleKryon
  class PicData < BaseData
    attr_accessor :name
    attr_accessor :filename
    
    attr_accessor :alt
    attr_accessor :caption
    
    attr_accessor :url
    attr_accessor :mirrors
    
    def initialize()
      super()
      
      @name = ''
      @filename = ''
      
      @alt = ''
      @caption = ''
      
      @url = ''
      @mirrors = {}
    end
    
    # Excludes @updated_on
    def ==(y)
      return @name == y.name &&
             @filename == y.filename &&
             @alt == y.alt &&
             @caption == y.caption &&
             @url == y.url &&
             @mirrors == y.mirrors
    end
    
    def to_s()
      s = ''
      
      if @name.empty?() || @name.strip().empty?()
        s << ('%-100s' % [@url])
      else
        s << ('%-30s' % [@name])
        s << (' | %30s' % [@filename]) unless @name == @filename
        
        s << (' | %30s' % [@alt]) unless @name == @alt
        s << (' | %60s' % [@caption])
      end
      
      return s
    end
  end
end
