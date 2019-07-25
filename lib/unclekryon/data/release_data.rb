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
  class ReleaseData < BaseData
    attr_accessor :title
    
    attr_accessor :url
    attr_accessor :mirrors
    
    attr_accessor :albums
    
    def initialize()
      super()
      
      @title = ''
      
      @url = ''
      @mirrors = {}
      
      @albums = []
    end
    
    def to_mini_s()
      return to_s(true)
    end
    
    def to_s(mini=false)
      s = ''
      s << ('%-10s' % [@title])
      s << (mini ? (' | %3d' % [@albums.length()]) : ("\n- " << @albums.join("\n- ")))
      return s
    end
  end
end
