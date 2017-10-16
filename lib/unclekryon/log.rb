#!/usr/bin/env ruby

require 'logger'
require 'singleton'

# TODO: make own methods; take in Exception/Error e; log e and e.backtrace.join("\n\t> ")
module UncleKryon
  class Log
    include Singleton
  
    attr_reader :log
  
    def initialize
      @log = Logger.new(STDOUT)
    end
  end
end

if $0 == __FILE__
  UncleKryon::Log.instance.log.fatal('oops!')
end
