# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'yaml'

require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/base_data'

module UncleKryon
  class BaseIso < BaseData
    attr_reader :name
    attr_reader :code

    def initialize
      super()

      @name = nil
      @code = nil
    end

    def self.fix_name(name)
      return flip_word_order(simplify_name(name))
    end

    def self.flip_word_order(word)
      # e.g., change 'English, Old' to 'Old English'
      return word.gsub(/([^\,\;]+)[[:space:]]*[\,\;]+[[:space:]]*([^\,\;]+)/,'\\2 \\1').strip
    end

    def self.simplify_code(code)
      # e.g., remove 'US-' from 'US-AL'
      return code.gsub(/[[:alnum:][:space:]]+\-[[:space:]]*/,'').strip
    end

    def self.simplify_name(name)
      # e.g., remove '(the)' from 'United States of America (the)'
      return name.gsub(/[[:space:]]*\([^\)]*\)[[:space:]]*/,'').strip
    end

    def ==(other)
      return @name == other.name && @code == other.code
    end

    def to_s
      return %Q(["#{@name}",#{@code}])
    end
  end

  class BaseIsos
    include Logging

    DEFAULT_DIR = 'iso'

    attr_reader :id
    attr_reader :values

    def initialize
      super()

      @id = self.class.get_class_name(self)
      @values = {}
    end

    def find(text)
      lang = find_by_name(text)
      return lang unless lang.nil?

      lang = find_by_code(text)
      return lang
    end

    def find_by_code(code)
      code = code.gsub(/[[:space:]]+/,'').downcase

      @values.each do |k,v|
        codes = nil

        if v.respond_to?(:codes)
          codes = v.codes()
        elsif v.respond_to?(:code)
          codes = [v.code]
        else
          raise "No codes()/code() method for class #{v.class.name}"
        end

        codes.each do |c|
          next if c.nil?
          c = c.gsub(/[[:space:]]+/,'').downcase
          return v if c == code
        end
      end

      return nil
    end

    def find_by_name(name)
      name = name.gsub(/[[:space:]]+/,'').downcase

      @values.each do |k,v|
        names = nil

        if v.respond_to?(:names)
          names = v.names()
        elsif v.respond_to?(:name)
          names = [v.name]
        else
          raise "No names()/name() method for class #{v.class.name}"
        end

        names.each do |n|
          next if n.nil?
          n = n.gsub(/[[:space:]]+/,'').downcase
          return v if n == name
        end
      end

      return nil
    end

    def load_file(filepath)
      y = YAML.unsafe_load_file(filepath)
      @values.merge!(y[@id])

      return self
    end

    def save_to_file(filepath)
      File.open(filepath,'w') do |f|
        v = {}
        v[@id] = @values
        YAML.dump(v,f)
      end
    end

    def sort_keys!
      # Old way: @values = @values.sort().to_h()

      new_values = {}

      @values.keys.sort.each do |code|
        new_values[code] = @values[code]
      end

      @values = new_values
      return self
    end

    def [](code)
      @values[code]
    end

    def []=(code,value)
      @values[code] = value
    end

    def self.get_class_name(class_var)
      return class_var.class.name.split('::').last
    end

    def key?(code)
      @values.key?(code)
    end

    def to_s
      s = ''.dup

      @values.each do |code,value|
        s << "#{code}: #{value}\n"
      end

      return s
    end
  end
end
