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
