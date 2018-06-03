#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2018 Jonathan Bradley Whited (@esotericpig)
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

require 'unclekryon/iso/country'
require 'unclekryon/iso/language'
require 'unclekryon/iso/usa_state'

module UncleKryon
  module Iso
    @@countries = nil
    @@languages = nil
    @@usa_states = nil
    
    def self.countries()
      if !@@countries
        @@countries = Countries.load_file()
      end
      return @@countries
    end
    
    def self.languages()
      if !@@languages
        @@languages = Languages.load_file()
      end
      return @@languages
    end
    
    def self.usa_states()
      if !@@usa_states
        @@usa_states = UsaStates.load_file()
      end
      return @@usa_states
    end
  end
end

if $0 == __FILE__
  puts UncleKryon::Iso.countries['USA']
  puts UncleKryon::Iso.languages['eng']
  puts UncleKryon::Iso.usa_states['AL']
end
