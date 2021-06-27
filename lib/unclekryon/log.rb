#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'logger'
require 'singleton'

module UncleKryon
  class UncleKryonLogger < Logger
    def initialize
      super(STDOUT)

      @progname = self.class.to_s()
    end

    def build_message(message,error: nil,**options)
      # Don't use mutable methods
      message += error.backtrace().map(){|e| "\n  > " + e}.join('') if !error.nil?

      return message
    end

    def error(message,error: nil,**options)
      super(build_message(message,error: error,**options))
    end

    def fatal(message,error: nil,**options)
      super(build_message(message,error: error,**options))
    end

    def unknown(message,error: nil,**options)
      super(build_message(message,error: error,**options))
    end

    def warn(message,error: nil,**options)
      super(build_message(message,error: error,**options))
    end
  end

  # Global for non-class use
  class Log < UncleKryonLogger
    include Singleton

    # Do NOT define vars here; had problems with @dev/@test breaking this class
  end

  # Mixin for class use
  module Logging
    def init_log()
    end

    def log()
      if !@log
        @log = UncleKryonLogger.new()
        @log.progname = self.class.to_s()

        init_log()
      end
      return @log
    end
  end
end

if $0 == __FILE__
  class Tester
    include UncleKryon::Logging

    def init_log()
      @log.progname.prepend("[Risky]")
    end

    def take_risk()
      log.fatal('Risky! Risky! Risky!')
    end
  end

  begin
    t = Tester.new()
    t.take_risk()

    raise 'Oops!'
  rescue StandardError => e
    UncleKryon::Log.instance.error(e.message,error: e)
    UncleKryon::Log.instance.fatal(e.message,error: e)
    UncleKryon::Log.instance.unknown(e.message,error: e)
    UncleKryon::Log.instance.warn(e.message,error: e)

    UncleKryon::Log.instance.warn("Don't Worry") do
      'This still works'
    end
  end
end
