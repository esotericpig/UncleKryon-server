#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2019 Jonathan Bradley Whited (@esotericpig)
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


require 'bundler/setup'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/Subregion
##
module UncleKryon
  class Subregion < BaseIso
    def initialize()
      super()
    end
  end
  
  class Subregions < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/subregions.yaml"
    
    def initialize()
      super()
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return Subregions.new().load_file(filepath)
    end
  end
end

if $0 == __FILE__
  puts UncleKryon::Subregions.load_file().to_s()
end
