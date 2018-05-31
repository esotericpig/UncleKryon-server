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
require 'yaml'

require 'unclekryon/iso/iso_base'

# TODO: make countries reflect countries listed on kryon site during each year parsing
# TODO: add find() methods on name/code/etc. as needed

##
# @see https://en.wikipedia.org/wiki/ISO_3166
# @see https://en.wikipedia.org/wiki/ISO_3166-1
# @see https://en.wikipedia.org/wiki/ISO_3166-2:GB
# @see https://www.iso.org/obp/ui/#search/code/
##
module UncleKryon
  class Country
    attr_reader :name
    attr_reader :alt_name
    attr_reader :display_name
    attr_reader :code
    attr_reader :alt_code
    attr_reader :display_code
    attr_reader :alpha2_code
    attr_reader :alpha3_code
    
    def initialize(row=nil)
      @name = nil
      @alt_name = nil
      @display_name = nil
      @code = nil
      @alt_code = nil
      @display_code = nil
      @alpha2_code = nil
      @alpha3_code = nil
      
      if row.is_a?(Array)
        @name = IsoBase.simplify_name(row[0])
        @alpha2_code = row[2]
        @alpha3_code = row[3]
        
        @display_name = @name
        @code = @alpha3_code
        @display_code = @alpha3_code
      end
    end
    
    def to_s()
      s = '['
      s << "\"#{@name}\",\"#{@alt_name}\",\"#{@display_name}\","
      s << "#{@code},#{@alt_code},#{@display_code},"
      s << "#{@alpha2_code},#{@alpha3_code}"
      s << ']'
      
      return s
    end
  end
  
  class Countries < IsoBase
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/countries.yaml"
    
    def initialize()
      super()
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return Countries.new().load_file(filepath)
    end
    
    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   https://www.iso.org/obp/ui/#search/code/
    def self.parse_and_save_filepath(parse_filepath,save_filepath=DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(open(parse_filepath),nil,'utf-8')
      tds = doc.css('td')
      
      countries = Countries.new()
      i = 0
      tr = []
      
      tds.each do |td|
        c = td.content
        c.gsub!(/[[:space:]]+/,' ')
        c.strip!()
        tr.push(c)
        
        if (i += 1) >= 5
          #puts tr.inspect()
          country = Country.new(tr)
          raise "Country already exists: #{country.inspect()}" if countries.key?(country.code)
          
          countries.values.each_value() do |v|
            puts "Duplicate country names: #{v.name}" if v.name == country.name
          end
          
          countries[country.code] = country
          tr.clear()
          i = 0
        end
      end
      
      countries.sort_keys!()
      countries.save_file(save_filepath)
    end
  end
end

if $0 == __FILE__
  if ARGV.length < 1
    puts UncleKryon::Countries.load_file().to_s()
  else
    UncleKryon::Countries.parse_and_save_filepath(ARGV[0],(ARGV.length >= 2) ? ARGV[1] :
      UncleKryon::Countries::DEFAULT_FILEPATH)
  end
end
