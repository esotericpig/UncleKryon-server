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
require 'yaml'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/ISO_3166-2:US
# @see https://www.iso.org/obp/ui/#iso:code:3166:US
##
module UncleKryon
  class UsaState < BaseIso
    def initialize(row=nil)
      super()
      
      if row.is_a?(Array)
        @name = self.class.simplify_name(row[2])
        @code = self.class.simplify_code(row[1])
      end
    end
  end
  
  class UsaStates < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/usa_states.yaml"
    
    def initialize()
      super()
      
      @id = 'USA States'
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return UsaStates.new().load_file(filepath)
    end
    
    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   https://www.iso.org/obp/ui/#iso:code:3166:US
    def self.parse_and_save_to_file(parse_filepath,save_filepath=DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(open(parse_filepath),nil,'utf-8')
      tds = doc.css('td')
      
      states = UsaStates.new()
      i = 0
      tr = []
      
      tds.each do |td|
        c = td.content
        c.gsub!(/[[:space:]]+/,' ')
        c.strip!()
        tr.push(c)
        
        if (i += 1) >= 7
          #puts tr.inspect()
          state = UsaState.new(tr)
          raise "USA state already exists: #{state.inspect()}" if states.key?(state.code)
          
          states.values.each_value() do |v|
            puts "Duplicate USA state names: #{v.name}" if v.name == state.name
          end
          
          states[state.code] = state
          tr.clear()
          i = 0
        end
      end
      
      states.sort_keys!()
      states.save_to_file(save_filepath)
    end
  end
end

if $0 == __FILE__
  if ARGV.length < 1
    puts UncleKryon::UsaStates.load_file().to_s()
  else
    UncleKryon::UsaStates.parse_and_save_to_file(ARGV[0],(ARGV.length >= 2) ? ARGV[1] :
      UncleKryon::UsaStates::DEFAULT_FILEPATH)
  end
end
