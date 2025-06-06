# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++

require 'unclekryon/data/base_data'

module UncleKryon
  class AumData < BaseData
    attr_accessor :title
    attr_accessor :subtitle
    attr_accessor :languages
    attr_accessor :timespan
    attr_accessor :filesize
    attr_accessor :filename

    attr_accessor :url
    attr_accessor :mirrors

    def initialize
      super

      @title = ''
      @subtitle = ''
      @languages = []
      @timespan = ''
      @filesize = ''
      @filename = ''

      @url = ''
      @mirrors = {}
    end

    # Excludes @updated_on
    def ==(other)
      return @title == other.title &&
             @subtitle == other.subtitle &&
             @languages == other.languages &&
             @timespan == other.timespan &&
             @filesize == other.filesize &&
             @filename == other.filename &&
             @url == other.url &&
             @mirrors == other.mirrors
    end

    def to_s
      s = ''
      s << format('%-40s', @title)
      s << format(' | %30s', @subtitle)
      s << format(' | %10s', @languages.join(';'))
      s << format(' | %10s', @timespan)
      s << format(' | %10s', @filesize)
      s << format(' | %30s', @filename)
      return s
    end
  end
end
