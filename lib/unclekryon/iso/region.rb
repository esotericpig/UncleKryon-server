#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'bundler/setup'

require 'unclekryon/iso/base_iso'

##
# @see https://en.wikipedia.org/wiki/Continent
##
module UncleKryon
  class Region < BaseIso
    def initialize()
      super()
    end
  end

  class Regions < BaseIsos
    DEFAULT_FILEPATH = "#{DEFAULT_DIR}/regions.yaml"

    def initialize()
      super()
    end

    def self.load_file(filepath=DEFAULT_FILEPATH)
      return Regions.new().load_file(filepath)
    end
  end
end

if $0 == __FILE__
  puts UncleKryon::Regions.load_file().to_s()
end
