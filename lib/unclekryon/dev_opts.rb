# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2018-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'singleton'

module UncleKryon
  class DevOpts
    include Singleton

    attr_accessor :dev
    attr_accessor :test

    alias_method :dev?,:dev
    alias_method :test?,:test

    def initialize
      @dev = false
      @test = false
    end
  end
end
