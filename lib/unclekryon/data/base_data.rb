#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2018 Jonathan Bradley Whited (@esotericpig)
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

require 'date'

require 'unclekryon/util'

module UncleKryon
  class BaseData
    attr_accessor :updated_on
    
    def initialize()
      update()
    end
    
    def initialize_copy(original)
      super(original)
      
      @updated_on = @updated_on.clone()
    end
    
    def update()
      @updated_on = Util.format_datetime(DateTime.now())
      return @updated_on
    end
    
    def self.max_updated_on(data)
      max = nil
      
      if data.is_a?(Hash)
        data.each() do |k,v|
          vuo = Util.parse_datetime_s(v.updated_on)
          max = vuo if max.nil?() || vuo > max
        end
      end
      
      return max
    end
    
    def self.max_updated_on_s(data)
      return Util.format_datetime(max_updated_on(data))
    end
  end
end
