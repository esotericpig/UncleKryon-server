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

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/ISO_3166
# @see https://en.wikipedia.org/wiki/ISO_3166-1
# @see https://en.wikipedia.org/wiki/ISO_3166-2:GB
# @see https://www.iso.org/obp/ui/#search/code/
##
module UncleKryon
  class Country < BaseIso
    attr_reader :names
    attr_reader :codes
    attr_reader :alpha2_code
    attr_reader :alpha3_code
    attr_reader :region

    def initialize(row = nil)
      super()

      @names = nil
      @codes = nil
      @alpha2_code = nil
      @alpha3_code = nil
      @region = nil

      if row.is_a?(Array)
        @name = self.class.simplify_name(row[0])
        @alpha2_code = row[2]
        @alpha3_code = row[3]

        @names = @name
        @code = @alpha3_code
        @codes = [@alpha3_code,@alpha2_code].compact.uniq
      end
    end

    def to_s
      s = '['.dup
      s << %("#{@name}","#{@names.join(';')}")
      s << %(,#{@code},"#{@codes.join(';')}",#{@alpha2_code},#{@alpha3_code})
      s << ",#{@region}"
      s << ']'

      return s
    end
  end

  class Countries < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/countries.yaml".freeze

    def self.load_file(filepath = DEFAULT_FILEPATH)
      return Countries.new.load_file(filepath)
    end

    # @param parse_filepath [String] use web browser's developer tools to copy & paste table HTML
    #                                into local file
    # @param save_filepath  [String] local file to save YAML to
    # @see   https://www.iso.org/obp/ui/#search/code/
    def self.parse_and_save_to_file(parse_filepath,save_filepath = DEFAULT_FILEPATH)
      doc = Nokogiri::HTML(URI(parse_filepath).open,nil,'utf-8')
      tds = doc.css('td')

      countries = Countries.new
      i = 0
      tr = []

      tds.each do |td|
        c = td.content
        c.gsub!(/[[:space:]]+/,' ')
        c.strip!
        tr.push(c)

        if (i += 1) >= 5
          # puts tr.inspect()
          country = Country.new(tr)
          raise "Country already exists: #{country.inspect}" if countries.key?(country.code)

          countries.values.each_value do |v|
            puts "Duplicate country names: #{v.name}" if v.name == country.name
          end

          countries[country.code] = country
          tr.clear
          i = 0
        end
      end

      countries.sort_keys!
      countries.save_to_file(save_filepath)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV.empty?
    puts UncleKryon::Countries.load_file
  else
    UncleKryon::Countries.parse_and_save_to_file(
      ARGV[0],(ARGV.length >= 2) ? ARGV[1] : UncleKryon::Countries::DEFAULT_FILEPATH
    )
  end
end
