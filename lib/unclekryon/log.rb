#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2017 Jonathan Bradley Whited (@esotericpig)
# 
# UncleKryon-server is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# UncleKryon-server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with UncleKryon-server.  If not, see <http://www.gnu.org/licenses/>.
###

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
    
    attr_accessor :dev
    attr_accessor :test
    
    alias_method :dev?,:dev
    alias_method :test?,:test
    
    def initialize()
      @dev = false
      @test = false
    end
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
