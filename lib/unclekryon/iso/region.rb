#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2019 Jonathan Bradley Whited (@esotericpig)
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

require 'bundler/setup'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/Continent
##
module UncleKryon
  class Region < BaseIso
    def initialize()
      super()
    end
  end
  
  class Regions < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/regions.yaml"
    
    def initialize()
      super()
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return Regions.new().load_file(filepath)
    end
  end
end

if $0 == __FILE__
  puts UncleKryon::Regions.load_file().to_s()
end