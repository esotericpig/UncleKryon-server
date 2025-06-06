# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++

require 'yaml'

require 'unclekryon/dev_opts'
require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/base_data'

require 'unclekryon/iso/base_iso'
require 'unclekryon/iso/can_prov_terr'
require 'unclekryon/iso/country'
require 'unclekryon/iso/language'
require 'unclekryon/iso/region'
require 'unclekryon/iso/subregion'
require 'unclekryon/iso/usa_state'

module UncleKryon
  class Iso
    DEFAULT_FILEPATH = "#{BaseIsos::DEFAULT_DIR}/iso.yaml".freeze
    ID = 'ISO'

    @can_provs_terrs = nil
    @countries = nil
    @iso = nil
    @languages = nil
    @regions = nil
    @subregions = nil
    @usa_states = nil

    attr_accessor :updated_can_provs_terrs_on
    attr_accessor :updated_countries_on
    attr_accessor :updated_languages_on
    attr_accessor :updated_regions_on
    attr_accessor :updated_subregions_on
    attr_accessor :updated_usa_states_on

    def initialize
      super

      update_all
    end

    def self.can_provs_terrs
      @can_provs_terrs ||= CanProvsTerrs.load_file
      return @can_provs_terrs
    end

    def self.countries
      @countries ||= Countries.load_file
      return @countries
    end

    def self.find_kryon_locations(text)
      locs = []

      # Fix bad data
      text = text.gsub(/\A[[:space:]]*SASKATOON-CALGARY[[:space:]]*\z/,
                       'SASKATOON, SASKATCHEWAN, CANADA / CALGARY, ALBERTA, CANADA')

      # Multiple countries are separated by '/' or '&'
      text.split(%r{[[:space:]]*[/&][[:space:]]*}).each do |t|
        # Fix misspellings and/or weird shortenings
        t = t.gsub(/Kansas[[:space:]]*,[[:space:]]*City/i,'Kansas City')
        t = t.gsub(/[+*]+/,'') # Means more countries, but won't worry about it (since not listed)
        t = t.gsub(/Berkeley[[:space:]]+Spings/i,'Berkeley Springs, WV')
        t = t.gsub(/SWITZ[[:space:]]*\z/i,'Switzerland')
        t = t.gsub(/\A[[:space:]]*NEWPORT[[:space:]]+BEACH[[:space:]]*\z/,'Newport Beach, California')
        t = t.gsub(/\A[[:space:]]*SAN[[:space:]]+RAFAEL[[:space:]]*\z/,'San Rafael, California')
        t = t.gsub(/\A[[:space:]]*MILANO,[[:space:]]*MARITTIMA[[:space:]]*\z/,'MILANO MARITTIMA, ITALY')
        t = t.gsub(/\A[[:space:]]*MAR[[:space:]]+DEL[[:space:]]+PLATA[[:space:]]*\z/,
                   'MAR DEL PLATA, ARGENTINA')
        t = t.gsub(/\A[[:space:]]*PATAGONIA[[:space:]]+CRUISE[[:space:]]+2012[[:space:]]*\z/,
                   'Patagonia, South America')
        t = t.gsub(/\A[[:space:]]*PHILADELPHIA,[[:space:]]+PENNSYLVANNIA[[:space:]]*\z/,
                   'Philadelphia, Pennsylvania')
        t = t.gsub(/\ATHE[[:space:]]+AWAKENING[[:space:]]+ZONE.COM\z/,'World')
        t = t.gsub(/\ASEDONA, AZ - Summer Light Conference\z/,'Sedona, AZ')
        t = t.gsub(/\AHAWAII CRUISE 11\z/,'Hawaii')
        t = t.gsub(/\A28 AUDIO FILES - 6 COUNTRIES\z/,'World')
        t = t.gsub(/\ABLOGTALKRADIO\.COM\z/,'World')
        t = t.gsub(/\AAWAKENINGZONE\.COM\z/,'World')
        t = t.gsub(/\AGEMATRIA\s+SEMINAR\z/,'Sedona, Arizona')
        t = t.gsub(/\AKONA,\s+HAWAI'I\z/,'Kona, Hawaii')
        t = t.gsub(/\ATALKSHOE\.COM\z/,'World')
        t = t.gsub(/\AConnor's\s+Corner\z/,'World')
        t = t.gsub(/\AUNITED\s+NATIONS,\s+NEW\s+YORK\s+CITY\z/i,'United Nations, New York City, NY')
        t = t.gsub(/\AMEDITERRANEAN\s+CRUISE\s+[[:digit:]]+\z/i,'Western Mediterranean')
        t = t.gsub(/\AHAWAI'I\s+CRUISE\s+[[:digit:]]+\z/i,'Hawaii')
        t = t.gsub(/\AALASKA\s+CRUISE\s+[[:digit:]]+\z/i,'Alaska')
        t = t.gsub(/\AGLASS\s+HOUSE\s+MT\.\s+\(AU\)\z/i,'Glass House Mountains, Australia')

        parts = t.split(/[[:space:],-]+/)
        last = parts.last
        last2 = (parts.length >= 2) ? (parts[-2] + last) : nil

        city = nil
        state = nil
        country = countries.find_by_name(last) # By name because e.g. code CO is Colorado and Colombia
        subregion = nil
        region = nil

        parse_state = true
        state_i = parts.length - 1

        # USA state?
        if country.nil?
          parse_state = false
          state = usa_states.find(last)

          if state.nil? && !last2.nil?
            state = usa_states.find_by_name(last2)
            state_i = parts.length - 2 unless state.nil?
          end

          if state.nil?
            # CAN prov/terr? (use state var)
            state = can_provs_terrs.find(last)

            if state.nil? && !last2.nil?
              state = can_provs_terrs.find_by_name(last2)
              state_i = parts.length - 2 unless state.nil?
            end

            if state.nil?
              # Try country code
              country = countries.find_by_code(last) # Try by code; e.g., CAN for Canada

              if country.nil?
                country = countries.find_by_name(t)
                state_i = 0 unless country.nil?
              end
              if country.nil? && !last2.nil?
                country = countries.find_by_name(last2)
                state_i = 0 unless country.nil?
              end

              if country.nil?
                # Subregion?
                subregion = subregions.find_by_name(t)
                subregion = subregions.find_by_name(last2) if subregion.nil? && !last2.nil?

                if subregion.nil?
                  # Region?
                  region = regions.find_by_name(t)
                  region = regions.find_by_name(last2) if region.nil? && !last2.nil?

                  if region.nil?
                    msg = %(No state/country/region: "#{text}","#{t}","#{last}")

                    if DevOpts.instance.dev?
                      raise msg
                    else
                      log.warn(msg)
                    end
                  else
                    region = region.code
                    state_i = 0
                  end
                else
                  subregion = subregion.code
                  state_i = 0
                end
              else
                country = country.code
                parse_state = true unless state_i == 0
              end
            else
              state = state.code
              country = countries.find_by_code('CAN').code
            end
          else
            state = state.code
            country = countries.find_by_code('USA').code
          end
        else
          country = country.code
        end

        if region.nil? || subregion.nil?
          # Not USA
          if parse_state && parts.length >= 2
            state = parts[-2].gsub(/[[:space:]]+/,' ').strip

            # CAN prov/terr? (use state var)
            if country == countries.find_by_code('CAN').code
              state = can_provs_terrs.find(state)

              if state.nil?
                if parts.length >= 3
                  state = can_provs_terrs.find_by_name(parts[-3] + parts[-2])
                  state_i = parts.length - 3 unless state.nil?
                end
              else
                state = state.code
                state_i = parts.length - 2
              end
            else
              if state.length == 2
                state = state.upcase
                state_i = parts.length - 2
              else
                state = nil
              end
            end
          end

          # City
          city = []
          (0...state_i).each do |i|
            c = parts[i].gsub(/[[:space:]]+/,' ').strip
            city.push(c) unless c.empty?
          end
          city = city.compact
          city = city.empty? ? nil : city.map(&:capitalize).join(' ')

          # Region
          region = countries.find_by_code(country).region unless country.nil?
        end

        # Location
        loc = [city,state,country,subregion,region] # Don't do compact(); we want all 4 ','
        locs.push(loc.join(',')) unless loc.compact.empty?
      end

      return locs.empty? ? nil : locs
    end

    def self.iso
      @iso ||= Iso.load_file
      return @iso
    end

    def self.languages
      @languages ||= Languages.load_file
      return @languages
    end

    def self.load_file(filepath = DEFAULT_FILEPATH)
      y = YAML.unsafe_load_file(filepath)
      iso = y[ID]
      return iso
    end

    def self.regions
      @regions ||= Regions.load_file
      return @regions
    end

    def save_to_file(filepath = DEFAULT_FILEPATH)
      File.open(filepath,'w') do |f|
        iso = {ID => self}
        YAML.dump(iso,f)
      end
    end

    def self.subregions
      @subregions ||= Subregions.load_file
      return @subregions
    end

    def update_all
      @updated_can_provs_terrs_on = BaseData.max_updated_on_s(self.class.can_provs_terrs.values)
      @updated_countries_on = BaseData.max_updated_on_s(self.class.countries.values)
      @updated_languages_on = BaseData.max_updated_on_s(self.class.languages.values)
      @updated_regions_on = BaseData.max_updated_on_s(self.class.regions.values)
      @updated_subregions_on = BaseData.max_updated_on_s(self.class.subregions.values)
      @updated_usa_states_on = BaseData.max_updated_on_s(self.class.usa_states.values)
    end

    def self.usa_states
      @usa_states ||= UsaStates.load_file
      return @usa_states
    end

    def to_s
      s = 'Updated On:'.dup
      s << "\n- CAN Provs/Terrs: #{@updated_can_provs_terrs_on}"
      s << "\n- Countries:  #{@updated_countries_on}"
      s << "\n- Languages:  #{@updated_languages_on}"
      s << "\n- Regions: #{@updated_regions_on}"
      s << "\n- Subregions: #{@updated_subregions_on}"
      s << "\n- USA States: #{@updated_usa_states_on}"
      return s
    end
  end
end

if $PROGRAM_NAME == __FILE__
  puts UncleKryon::Iso.can_provs_terrs['ON']
  puts UncleKryon::Iso.countries['USA']
  puts UncleKryon::Iso.languages['eng']
  puts UncleKryon::Iso.regions['South America']
  puts UncleKryon::Iso.subregions['Pantagonia']
  puts UncleKryon::Iso.usa_states['AL']
  puts UncleKryon::Iso.iso
end
