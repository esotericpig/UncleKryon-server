# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'unclekryon/util'

require 'unclekryon/data/base_data'

module UncleKryon
  class AlbumData < BaseData
    attr_accessor :date_begin
    attr_accessor :date_end
    attr_accessor :title
    attr_accessor :locations
    attr_accessor :languages

    attr_accessor :url
    attr_accessor :mirrors

    attr_accessor :desc

    attr_accessor :pics
    attr_accessor :aums
    attr_accessor :scrolls
    attr_accessor :visions

    attr_accessor :dump

    def initialize
      super()

      @date_begin = ''
      @date_end = ''
      @title = ''
      @locations = []
      @languages = []

      @url = ''
      @mirrors = {}

      @desc = ''

      @pics = {}
      @aums = {}
      @scrolls = {}
      @visions = {}

      @dump = []
    end

    def initialize_copy(original)
      super(original)

      @date_begin = @date_begin.clone
      @date_end = @date_end.clone
      @title = @title.clone
      @locations = @locations.clone
      @languages = @languages.clone

      @url = @url.clone
      @mirrors = @mirrors.clone

      @desc = @desc.clone

      @pics = @pics.clone
      @aums = @aums.clone
      @scrolls = @scrolls.clone
      @visions = @visions.clone

      @dump = @dump.clone
    end

    def update_if_not_empty!(album)
      @date_begin = album.date_begin unless Util.empty_s?(album.date_begin)
      @date_end = album.date_end unless Util.empty_s?(album.date_end)
      @title = album.title unless Util.empty_s?(album.title)
      @locations |= album.locations unless album.locations.nil?
      @languages |= album.languages unless album.languages.nil?

      @desc = album.desc unless Util.empty_s?(album.desc)

      @pics |= album.pics unless album.pics.nil?
      @aums |= album.aums unless album.aums.nil?
      @scrolls |= album.scrolls unless album.scrolls.nil?
      @visions |= album.visions unless album.visions.nil?

      @dump |= album.dump unless album.dump.nil?
    end

    # Excludes @updated_on and @dump
    def ==(other)
      return @date_begin == other.date_begin &&
             @date_end == other.date_end &&
             @title == other.title &&
             @locations == other.locations &&
             @languages == other.languages &&
             @url == other.url &&
             @mirrors == other.mirrors &&
             @desc == other.desc &&
             @pics == other.pics &&
             @aums == other.aums &&
             @scrolls == other.scrolls &&
             @visions == other.visions
    end

    def to_mini_s
      return to_s(true)
    end

    def to_s(mini=false)
      s = ''
      s << ('%-10s=>%-10s' % [@date_begin,@date_end])
      s << (' | %60s' % [@title])
      s << (' | %25s' % [@locations.join(';')])
      s << (' | %10s' % [@languages.join(';')])

      s << "\n- #{@desc}" unless mini

      #s << (mini ? (' | pics:%3d'    % [@pics.length()]) :
      #     ("\n- Pics:\n  - " << @pics.join("\n  - ")))
      #s << (mini ? (' | aums:%3d'    % [@aums.length()]) :
      #     ("\n- Aums:\n  - " << @aums.join("\n  - ")))
      #s << (mini ? (' | scrolls:%3d' % [@scrolls.length()]) :
      #     ("\n- Scrolls:\n - " << @scrolls.join("\n  - ")))
      #s << (mini ? (' | visions:%3d' % [@visions.length()]) :
      #     ("\n- Visions:\n - " << @visions.join("\n  - ")))

      s << (mini ? (' | dump:%3d' % [@dump.length]) : ("\n- Dump:\n  - " << @dump.join("\n  - ")))
      return s
    end
  end
end
