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

module UncleKryon
  class TimeData
    attr_accessor :hours
    attr_accessor :mins
    attr_accessor :secs
    
    def initialize(time=nil)
      @hours = 0
      @mins = 0
      @secs = 0
      
      if !time.nil? && !time.empty?
        time = time.gsub(/\A[^\(]+\(/,'') # "One hour 6 minutes - (66 minutes)"
        time = time.gsub(/[^[[:digit:]]\:\.]+/,'')
        a = time.split(/[\:\.]/)
        
        if a.length == 1
          @mins = a[0].to_i
        elsif a.length == 2
          @mins = a[0].to_i
          @secs = a[1].to_i
        elsif a.length >= 3
          @hours = a[0].to_i
          @mins = a[1].to_i
          @secs = a[2].to_i
        end
        
        if @secs >= 60
          @mins += (@secs / 60)
          @secs = @secs % 60
        end
        if @mins >= 60
          @hours += (@mins / 60)
          @mins = @mins % 60
        end
      end
    end
    
    def to_s
      return "#{@hours}:#{@mins}:#{@secs}"
    end
  end
end
