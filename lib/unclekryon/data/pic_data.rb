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
  class PicData < BaseData
    attr_accessor :name
    attr_accessor :filename

    attr_accessor :alt
    attr_accessor :caption

    attr_accessor :url
    attr_accessor :mirrors

    def initialize
      super()

      @name = ''
      @filename = ''

      @alt = ''
      @caption = ''

      @url = ''
      @mirrors = {}
    end

    # Excludes @updated_on
    def ==(other)
      return @name == other.name &&
             @filename == other.filename &&
             @alt == other.alt &&
             @caption == other.caption &&
             @url == other.url &&
             @mirrors == other.mirrors
    end

    def to_s
      s = ''.dup

      if @name.empty? || @name.strip.empty?
        s << ('%-100s' % [@url])
      else
        s << ('%-30s' % [@name])
        s << (' | %30s' % [@filename]) unless @name == @filename

        s << (' | %30s' % [@alt]) unless @name == @alt
        s << (' | %60s' % [@caption])
      end

      return s
    end
  end
end
