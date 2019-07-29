#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
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
# along with UncleKryon-server.  If not, see <https://www.gnu.org/licenses/>.
#++


require 'bundler/setup'

require 'nokogiri'
require 'open-uri'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/ISO_3166-2:CA
# @see https://www.iso.org/obp/ui/#iso:code:3166:CA
##
module UncleKryon
  class CanProvTerr < BaseIso
    def initialize(row=nil)
      super()
      
      if row.is_a?(Array)
        @name = self.class.simplify_name(row[2])
        @code = self.class.simplify_code(row[1])
      end
    end
  end
  
  class CanProvsTerrs < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/can_provs_terrs.yaml"
    
    def initialize()
      super()
      
      @id = 'CAN Provinces & Territories'
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return CanProvsTerrs.new().load_file(filepath)
    end
    
    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   https://www.iso.org/obp/ui/#iso:code:3166:CA
    def self.parse_and_save_to_file(parse_filepath,save_filepath=DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(open(parse_filepath),nil,'utf-8')
      trs = doc.css('tr')
      
      provs_terrs = CanProvsTerrs.new()
      
      trs.each() do |tr|
        tds = tr.css('td')
        
        # Skip French; we just want English
        next if tds[4].content.gsub(/[[:space:]]+/,' ').strip().downcase() == 'fr'
        
        i = 0
        tr = []
        
        tds.each() do |td|
          c = td.content
          c.gsub!(/[[:space:]]+/,' ')
          c.strip!()
          tr.push(c)
          
          if (i += 1) >= 7
            #puts tr.inspect()
            prov_terr = CanProvTerr.new(tr)
            raise "CAN prov/terr already exists: #{prov_terr.inspect()}" if provs_terrs.key?(prov_terr.code)
            
            provs_terrs.values.each_value() do |v|
              puts "Duplicate CAN prov/terr names: #{v.name}" if v.name == prov_terr.name
            end
            
            provs_terrs[prov_terr.code] = prov_terr
            tr.clear()
            i = 0
          end
        end
      end
      
      provs_terrs.sort_keys!()
      provs_terrs.save_to_file(save_filepath)
    end
  end
end

if $0 == __FILE__
  if ARGV.length < 1
    puts UncleKryon::CanProvsTerrs.load_file().to_s()
  else
    UncleKryon::CanProvsTerrs.parse_and_save_to_file(ARGV[0],(ARGV.length >= 2) ? ARGV[1] :
      UncleKryon::CanProvsTerrs::DEFAULT_FILEPATH)
  end
end
