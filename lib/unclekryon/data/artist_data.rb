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

module UncleKryon
  class ArtistData
    attr_accessor :releases
    attr_accessor :albums
    attr_accessor :aums
    attr_accessor :pics
    
    def initialize
      @releases = {}
      @albums = {}
      @aums = {}
      @pics = {}
    end
  end
end
