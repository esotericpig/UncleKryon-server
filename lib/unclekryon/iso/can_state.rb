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

require 'nokogiri'
require 'open-uri'

require 'unclekryon/iso/iso_base'

##
# I know that they are provinces/territories, but calling them states for consistency.
# 
# @see https://en.wikipedia.org/wiki/ISO_3166-2:CA
# @see https://www.iso.org/obp/ui/#iso:code:3166:CA
##
module UncleKryon
  class CanState
    attr_reader :name
    attr_reader :code
    
    def initialize(row=nil)
      @name = nil
      @code = nil
      
      if row.is_a?(Array)
        @name = IsoBase.simplify_name(row[2])
        @code = IsoBase.simplify_code(row[1])
      end
    end
    
    def to_s()
      return %Q(["#{@name}",#{@code}])
    end
  end
  
  class CanStates < IsoBase
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/can_states.yaml"
    DEFAULT_ID = 'CAN States'
    
    def initialize()
      super()
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return CanStates.new().load_file(filepath,DEFAULT_ID)
    end
    
    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   https://www.iso.org/obp/ui/#iso:code:3166:CA
    def self.parse_and_save_filepath(parse_filepath,save_filepath=DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(open(parse_filepath),nil,'utf-8')
      trs = doc.css('tr')
      
      states = CanStates.new()
      
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
            state = CanState.new(tr)
            raise "CAN state already exists: #{state.inspect()}" if states.key?(state.code)
            
            states.values.each_value() do |v|
              puts "Duplicate CAN state names: #{v.name}" if v.name == state.name
            end
            
            states[state.code] = state
            tr.clear()
            i = 0
          end
        end
      end
      
      states.sort_keys!()
      states.save_file(save_filepath,DEFAULT_ID)
    end
  end
end

if $0 == __FILE__
  if ARGV.length < 1
    puts UncleKryon::CanStates.load_file().to_s()
  else
    UncleKryon::CanStates.parse_and_save_filepath(ARGV[0],(ARGV.length >= 2) ? ARGV[1] :
      UncleKryon::CanStates::DEFAULT_FILEPATH)
  end
end
