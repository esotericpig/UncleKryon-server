# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2022 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++

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

    def initialize(row = nil)
      super()

      @names = nil
      @codes = nil
      @alpha2_code = nil
      @alpha3_code = nil
      @alpha3_code_b = nil

      if row.is_a?(Array)
        @names = row[2].split(';').compact.uniq.map { |n| self.class.fix_name(n) }
        @alpha2_code = row[1].empty? ? nil : row[1]
        @alpha3_code = row[0].split(/[[:space:]]*[()][[:space:]]*/)

        if @alpha3_code.length <= 1
          @alpha3_code = row[0]
        else
          prev_was_tag = true

          @alpha3_code.each_with_index do |c,i|
            c.strip!
            c_up = c.upcase

            if c_up == 'B' || c_up == 'T'
              raise "Invalid alpha-3 code for: #{@names},#{@alpha2_code},#{@alpha3_code}" if prev_was_tag

              case c_up
              when 'B'
                raise "Multiple alpha3_code_b: #{@alpha3_code}" unless @alpha3_code_b.nil?
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
        # @names = @names
        @code = @alpha3_code
        @codes = [@alpha3_code,@alpha3_code_b,@alpha2_code].compact.uniq
      end
    end

    # @see Languages.parse_and_save_to_file(...)
    def ==(other)
      return super &&
             @names == other.names &&
             @codes == other.codes &&
             @alpha2_code == other.alpha2_code &&
             @alpha3_code == other.alpha3_code &&
             @alpha3_code_b == other.alpha3_code_b
    end

    def to_s
      s = '['.dup
      s << %("#{@name}","#{@names.join(';')}",)
      s << %(#{@code},"#{@codes.join(';')}",)
      s << "#{@alpha2_code},#{@alpha3_code},#{@alpha3_code_b}"
      s << ']'

      return s
    end
  end

  class Languages < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/languages.yaml".freeze

    def find_by_kryon(text,add_english: false,**_options)
      langs = []
      regexes = [
        %r{[[:space:]]*[/+][[:space:]]*}, # Multiple languages are usually separated by '/'
        /[[:space:]]+/,                   # Sometimes separated by space/newline
      ]

      regexes.each_with_index do |regex,i|
        try_next_regex = false

        text.split(regex).each do |t|
          # Fix misspellings and/or weird shortenings
          t = t.clone
          t.gsub!(/\AFRENC\z/i,'French')
          t.gsub!(/[+*]+/,'') # Means more languages, but won't worry about it (since not listed)
          t.gsub!(/\ASPAN\z/i,'Spanish')
          t.gsub!(/\AENGLSH\z/i,'English')
          t.gsub!(/\AHUNGARY\z/i,'Hungarian')

          lang = find(t)

          if lang.nil?
            if i >= (regexes.length - 1)
              msg = "No language found for: #{t}"

              if DevOpts.instance.dev?
                raise msg
              else
                log.warn(msg)
              end
            else
              log.warn("Not a language; trying next regex: #{t}")

              # Try next regex.
              langs.clear
              try_next_regex = true
              break
            end
          else
            langs.push(lang.code)
          end
        end

        # No problem with this regex, so bail out.
        break unless try_next_regex
      end

      eng_code = find_by_code('eng').code

      langs.push(eng_code) if add_english && !langs.include?(eng_code)

      return langs.empty? ? nil : langs
    end

    def self.load_file(filepath = DEFAULT_FILEPATH)
      return Languages.new.load_file(filepath)
    end

    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML
    #                                into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   http://www.loc.gov/standards/iso639-2/php/code_list.php
    def self.parse_and_save_to_file(parse_filepath,save_filepath = DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(URI(parse_filepath).open,nil,'utf-8')
      tds = doc.css('td')

      langs = Languages.new
      i = 0
      tr = []

      tds.each do |td|
        c = td.content
        c.gsub!(/[[:space:]]+/,' ')
        c.strip!
        tr.push(c)

        if (i += 1) >= 5
          # puts tr.inspect()

          add_it = true
          lang = Language.new(tr)

          if langs.key?(lang.code)
            # There were so many duplicates, so added comparison check
            raise "Language already exists: #{lang.inspect}" if lang != langs[lang.code]
            add_it = false
          else
            langs.values.each_value do |v|
              puts "Duplicate lang names: #{v.name}" if v.name == lang.name
            end
          end

          langs[lang.code] = lang if add_it
          tr.clear
          i = 0
        end
      end

      langs.sort_keys!
      langs.save_to_file(save_filepath)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts UncleKryon::Languages.load_file
  else
    UncleKryon::Languages.parse_and_save_to_file(
      ARGV[0],(ARGV.length >= 2) ? ARGV[1] : UncleKryon::Languages::DEFAULT_FILEPATH
    )
  end
end
