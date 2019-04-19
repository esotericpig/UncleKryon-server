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

require 'yaml'

require 'unclekryon/dev_opts'
require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/base_data'

require 'unclekryon/iso/base_iso'
require 'unclekryon/iso/can_state'
require 'unclekryon/iso/country'
require 'unclekryon/iso/language'
require 'unclekryon/iso/region'
require 'unclekryon/iso/usa_state'

module UncleKryon
  class Iso
    DEFAULT_FILEPATH = "#{BaseIsos::DEFAULT_DIR}/iso.yaml"
    ID = 'ISO'
    
    @@can_states = nil
    @@countries = nil
    @@iso = nil
    @@languages = nil
    @@regions = nil
    @@usa_states = nil
    
    attr_accessor :updated_can_states_on
    attr_accessor :updated_countries_on
    attr_accessor :updated_languages_on
    attr_accessor :updated_regions_on
    attr_accessor :updated_usa_states_on
    
    def initialize()
      super()
      
      update_all()
    end
    
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
      
      # Fix bad data
      text = text.gsub(/\A[[:space:]]*SASKATOON\-CALGARY[[:space:]]*\z/,'SASKATOON, SASKATCHEWAN, CANADA / CALGARY, ALBERTA, CANADA')
      
      # Multiple countries are separated by '/' or '&'
      text.split(/[[:space:]]*[\/\&][[:space:]]*/).each() do |t|
        # Fix misspellings and/or weird shortenings
        t = t.gsub(/Kansas[[:space:]]*\,[[:space:]]*City/i,'Kansas City')
        t = t.gsub(/[\+\*]+/,'') # Means more countries, but won't worry about it (since not listed)
        t = t.gsub(/Berkeley[[:space:]]+Spings/i,'Berkeley Springs, WV')
        t = t.gsub(/SWITZ[[:space:]]*\z/i,'Switzerland')
        t = t.gsub(/\A[[:space:]]*NEWPORT[[:space:]]+BEACH[[:space:]]*\z/,'Newport Beach, California')
        t = t.gsub(/\A[[:space:]]*SAN[[:space:]]+RAFAEL[[:space:]]*\z/,'San Rafael, California')
        t = t.gsub(/\A[[:space:]]*MILANO\,[[:space:]]*MARITTIMA[[:space:]]*\z/,'MILANO MARITTIMA, ITALY')
        t = t.gsub(/\A[[:space:]]*MAR[[:space:]]+DEL[[:space:]]+PLATA[[:space:]]*\z/,'MAR DEL PLATA, ARGENTINA')
        
        parts = t.split(/[[:space:]\,\-]+/)
        last = parts.last
        last2 = (parts.length() >= 2) ? (parts[-2] + last) : nil
        
        city = nil
        state = nil
        country = countries().find_by_name(last) # By name because e.g. code CO is Colorado and Colombia
        region = nil
        
        parse_state = true
        state_i = parts.length() - 1
        
        # USA state?
        if country.nil?()
          parse_state = false
          state = usa_states().find(last)
          
          if state.nil?() && !last2.nil?()
            state = usa_states().find_by_name(last2)
            state_i = parts.length() - 2 unless state.nil?()
          end
          
          if state.nil?()
            # CAN state?
            state = can_states().find(last)
            
            if state.nil?() && !last2.nil?()
              state = can_states().find_by_name(last2)
              state_i = parts.length() - 2 unless state.nil?()
            end
            
            if state.nil?()
              # Try country code
              country = countries().find_by_code(last) # Try by code; e.g., CAN for Canada
              
              if country.nil?()
                country = countries().find_by_name(t)
                state_i = 0 unless country.nil?()
              end
              
              if country.nil?()
                # Region?
                region = regions().find_by_name(t)
                
                if region.nil?()
                  msg = %Q(No state/country/region: "#{text}","#{t}","#{last}")
                  
                  if DevOpts.instance.dev?()
                    raise msg
                  else
                    log.warn(msg)
                  end
                else
                  region = region.code
                  state_i = 0
                end
              else
                country = country.code
                parse_state = true unless state_i == 0
              end
            else
              state = state.code
              country = countries().find_by_code('CAN').code
            end
          else
            state = state.code
            country = countries().find_by_code('USA').code
          end
        else
          country = country.code
        end
        
        if region.nil?()
          # Not USA
          if parse_state
            if parts.length() >= 2
              state = parts[-2].gsub(/[[:space:]]+/,' ').strip()
              
              # CAN state?
              if country == countries().find_by_code('CAN').code
                state = can_states().find(state)
                
                if state.nil?()
                  if parts.length() >= 3
                    state = can_states().find_by_name(parts[-3] + parts[-2])
                    state_i = parts.length() - 3 unless state.nil?()
                  end
                else
                  state = state.code
                  state_i = parts.length() - 2
                end
              else
                if state.length() == 2
                  state = state.upcase()
                  state_i = parts.length() - 2
                else
                  state = nil
                end
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
          
          # Region
          if !country.nil?()
            region = countries().find_by_code(country).region
          end
        end
        
        # Location
        loc = [city,state,country,region] # Don't do compact(); we won't all 4 ','
        locs.push(loc.join(',')) unless loc.compact().empty?()
      end
      
      return locs.empty?() ? nil : locs
    end
    
    def self.iso()
      if !@@iso
        @@iso = Iso.load_file()
      end
      return @@iso
    end
    
    def self.languages()
      if !@@languages
        @@languages = Languages.load_file()
      end
      return @@languages
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      y = YAML.load_file(filepath)
      iso = y[ID]
      return iso
    end
    
    def self.regions()
      if !@@regions
        @@regions = Regions.load_file()
      end
      return @@regions
    end
    
    def save_to_file(filepath=DEFAULT_FILEPATH)
      File.open(filepath,'w') do |f|
        iso = {ID=>self}
        YAML.dump(iso,f)
      end
    end
    
    def update_all()
      @updated_can_states_on = BaseData.max_updated_on_s(self.class.can_states.values)
      @updated_countries_on = BaseData.max_updated_on_s(self.class.countries.values)
      @updated_languages_on = BaseData.max_updated_on_s(self.class.languages.values)
      @updated_regions_on = BaseData.max_updated_on_s(self.class.regions.values)
      @updated_usa_states_on = BaseData.max_updated_on_s(self.class.usa_states.values)
    end
    
    def self.usa_states()
      if !@@usa_states
        @@usa_states = UsaStates.load_file()
      end
      return @@usa_states
    end
    
    def to_s()
      s = 'Updated On:'
      s << "\n- CAN States: #{@updated_can_states_on}"
      s << "\n- Countries:  #{@updated_countries_on}"
      s << "\n- Languages:  #{@updated_languages_on}"
      s << "\n- Regions: #{@updated_regions_on}"
      s << "\n- USA States: #{@updated_usa_states_on}"
      return s
    end
  end
end

if $0 == __FILE__
  puts UncleKryon::Iso.can_states['ON']
  puts UncleKryon::Iso.countries['USA']
  puts UncleKryon::Iso.languages['eng']
  puts UncleKryon::Iso.regions['South America']
  puts UncleKryon::Iso.usa_states['AL']
  puts UncleKryon::Iso.iso
end
