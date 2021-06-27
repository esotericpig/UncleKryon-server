#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'unclekryon/data/base_data'

module UncleKryon
  class ReleaseData < BaseData
    attr_accessor :title

    attr_accessor :url
    attr_accessor :mirrors

    attr_accessor :albums

    def initialize()
      super()

      @title = ''

      @url = ''
      @mirrors = {}

      @albums = []
    end

    def to_mini_s()
      return to_s(true)
    end

    def to_s(mini=false)
      s = ''
      s << ('%-10s' % [@title])
      s << (mini ? (' | %3d' % [@albums.length()]) : ("\n- " << @albums.join("\n- ")))
      return s
    end
  end
end
