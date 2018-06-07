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

require 'unclekryon/log'

require 'unclekryon/iso/can_state'
require 'unclekryon/iso/country'
require 'unclekryon/iso/language'
require 'unclekryon/iso/usa_state'

module UncleKryon
  module Iso
    @@can_states = nil
    @@countries = nil
    @@languages = nil
    @@usa_states = nil
    
    def self.can_states()
      if !@@can_states
        @@can_states = CanStates.load_file()
      end
      return @@can_states
    end
    
    def self.countries()
      if !@@countries
        @@countries = Countries.load_file()
      end
      return @@countries
    end
    
    def self.find_kryon_locations(text)
      locs = []
      
      # Multiple countries are separated by '/'
      text.split(/[[:space:]]*\/[[:space:]]*/).each() do |t|
        # Fix misspellings and/or weird shortenings
        t = t.gsub(/Kansas[[:space:]]*\,[[:space:]]*City/i,'Kansas City')
        t = t.gsub(/[\+\*]+/,'') # Means more countries, but won't worry about it (since not listed)
        
        parts = t.split(/[[:space:]\,\-]+/)
        last = parts.last
        
        city = nil
        state = nil
        country = countries().find_by_name(last) # By name because e.g. code CO is Colorado and Colombia
        
        parse_country = true
        state_i = parts.length() - 1
        
        # USA state
        if country.nil?()
          parse_country = false
          state = usa_states().find(last)
          
          if state.nil?() && parts.length() >= 2
            state = usa_states().find(parts[-2] + last)
            state_i = parts.length() - 2 unless state.nil?()
          end
          
          if state.nil?()
            # CAN state
            state = can_states().find(last)
            
            if state.nil?()
              # Try country again
              country = countries().find_by_code(last) # Try by code; e.g., CAN for Canada
              
              if country.nil?()
                msg = %Q(No country/state: "#{text}","#{t}","#{last}")
                
                if Log.instance.dev?()
                  raise msg
                else
                  log.warn(msg)
                end
              else
                parse_country = true
              end
            else
              state = state.code
              country = countries().find_by_code('CAN').code
            end
          else
            state = state.code
            country = countries().find_by_code('USA').code
          end
        end
        
        # Not USA
        if parse_country
          country = country.code
          
          if parts.length() >= 2
            state = parts[-2].gsub(/[[:space:]]+/,' ').strip()
            
            if state.length() == 2
              state = state.upcase()
              state_i = parts.length() - 2
            else
              state = nil
            end
          end
        end
        
        # City
        city = []
        for i in 0...state_i
          c = parts[i].gsub(/[[:space:]]+/,' ').strip()
          city.push(c) unless c.empty?()
        end
        city = city.compact()
        city = city.empty?() ? nil : city.map(&:capitalize).join(' ')
        
        # Location
        loc = [city,state,country].compact()
        locs.push(loc.join(', ')) unless loc.empty?()
      end
      
      return locs.empty?() ? nil : locs.join(';')
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
  puts UncleKryon::Iso.can_states['ON']
  puts UncleKryon::Iso.countries['USA']
  puts UncleKryon::Iso.languages['eng']
  puts UncleKryon::Iso.usa_states['AL']
end
