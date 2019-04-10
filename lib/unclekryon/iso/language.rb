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

require 'nokogiri'
require 'open-uri'
require 'yaml'

require 'unclekryon/dev_opts'
require 'unclekryon/log'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/ISO_639
# @see http://www.loc.gov/standards/iso639-2/php/code_list.php
# @see http://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
##
module UncleKryon
  class Language < BaseIso
    attr_reader :names
    attr_reader :codes
    attr_reader :alpha2_code
    attr_reader :alpha3_code
    attr_reader :alpha3_code_b
    
    def initialize(row=nil)
      super()
      
      @names = nil
      @codes = nil
      @alpha2_code = nil
      @alpha3_code = nil
      @alpha3_code_b = nil
      
      if row.is_a?(Array)
        @names = row[2].split(';').compact().uniq().map(&self.class.method(:fix_name))
        @alpha2_code = row[1].empty?() ? nil : row[1]
        @alpha3_code = row[0].split(/[[:space:]]*[\(\)][[:space:]]*/)
        
        if @alpha3_code.length <= 1
          @alpha3_code = row[0]
        else
          prev_was_tag = true
          
          @alpha3_code.each_with_index() do |c,i|
            c.strip!()
            c_up = c.upcase()
            
            if c_up == 'B' || c_up == 'T'
              if prev_was_tag
                raise "Invalid alpha-3 code for: #{@names},#{@alpha2_code},#{@alpha3_code}"
              end
              
              case c_up
              when 'B'
                raise "Multiple alpha3_code_b: #{@alpha3_code}" unless @alpha3_code_b.nil?()
                @alpha3_code_b = @alpha3_code[i - 1]
              when 'T'
                raise "Multiple alpha3_code (T): #{@alpha3_code}" unless @alpha3_code.is_a?(Array)
                @alpha3_code = @alpha3_code[i - 1]
              end
              
              prev_was_tag = true
            else
              prev_was_tag = false
            end
          end
          
          # Wasn't set in the above loop?
          if @alpha3_code.is_a?(Array)
            raise "Invalid alpha-3 code for: #{@names},#{@alpha2_code},#{@alpha3_code}"
          end
        end
        
        @name = @names[0]
        @names = @names
        @code = @alpha3_code
        @codes = [@alpha3_code,@alpha3_code_b,@alpha2_code].compact().uniq()
      end
    end
    
    # @see Languages.parse_and_save_to_file(...)
    def ==(lang)
      return super(lang) &&
        @names == lang.names &&
        @codes == lang.codes &&
        @alpha2_code == lang.alpha2_code &&
        @alpha3_code == lang.alpha3_code &&
        @alpha3_code_b == lang.alpha3_code_b
    end
    
    def to_s()
      s = '['
      s << %Q("#{@name}","#{@names.join(';')}",)
      s << %Q(#{@code},"#{@codes.join(';')}",)
      s << %Q(#{@alpha2_code},#{@alpha3_code},#{@alpha3_code_b})
      s << ']'
      
      return s
    end
  end
  
  class Languages < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/languages.yaml"
    
    def initialize()
      super()
    end
    
    def find_by_kryon(text,add_english: false,**options)
      langs = []
      regexes = [
          /[[:space:]]*\/[[:space:]]*/, # Multiple languages are usually separated by '/'
          /[[:space:]]+/                # Sometimes separated by space/newline
        ]
      
      regexes.each_with_index() do |regex,i|
        text.split(regex).each() do |t|
          # Fix misspellings and/or weird shortenings
          t = t.clone()
          t.gsub!(/\AFRENC\z/i,'French')
          t.gsub!(/[\+\*]+/,'') # Means more languages, but won't worry about it (since not listed)
          t.gsub!(/\ASPAN\z/i,'Spanish')
          t.gsub!(/\AENGLSH\z/i,'English')
          t.gsub!(/\AHUNGARY\z/i,'Hungarian')
          
          lang = find(t)
          
          if lang.nil?()
            if i >= (regexes.length() - 1)
              msg = "No language found for: #{t}"
              
              if DevOpts.instance.dev?()
                raise msg
              else
                log.warn(msg)
              end
            else
              log.warn("Not a language; trying next regex: #{t}")
              
              # Try next regex
              langs.clear()
              next
            end
          else
            langs.push(lang.code)
          end
        end
        
        # No problem with this regex, so bail out
        break
      end
      
      eng_code = find_by_code('eng').code
      
      if add_english && !langs.include?(eng_code)
        langs.push(eng_code)
      end
      
      return langs.empty?() ? nil : langs
    end
    
    def self.load_file(filepath=DEFAULT_FILEPATH)
      return Languages.new().load_file(filepath)
    end
    
    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   http://www.loc.gov/standards/iso639-2/php/code_list.php
    def self.parse_and_save_to_file(parse_filepath,save_filepath=DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(open(parse_filepath),nil,'utf-8')
      tds = doc.css('td')
      
      langs = Languages.new()
      i = 0
      tr = []
      
      tds.each do |td|
        c = td.content
        c.gsub!(/[[:space:]]+/,' ')
        c.strip!()
        tr.push(c)
        
        if (i += 1) >= 5
          #puts tr.inspect()
          
          add_it = true
          lang = Language.new(tr)
          
          if langs.key?(lang.code)
            # There were so many duplicates, so added comparison check
            raise "Language already exists: #{lang.inspect()}" if lang != langs[lang.code]
            add_it = false
          else
            langs.values.each_value() do |v|
              puts "Duplicate lang names: #{v.name}" if v.name == lang.name
            end
          end
          
          langs[lang.code] = lang if add_it
          tr.clear()
          i = 0
        end
      end
      
      langs.sort_keys!()
      langs.save_to_file(save_filepath)
    end
  end
end

if $0 == __FILE__
  if ARGV.length < 1
    puts UncleKryon::Languages.load_file().to_s()
  else
    UncleKryon::Languages.parse_and_save_to_file(ARGV[0],(ARGV.length >= 2) ? ARGV[1] :
      UncleKryon::Languages::DEFAULT_FILEPATH)
  end
end
