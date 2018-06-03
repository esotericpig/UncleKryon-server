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

require 'yaml'

module UncleKryon
  class IsoBase
    DEFAULT_DIR = 'iso'
    
    attr_reader :values
    
    def initialize()
      @values = {}
    end
    
    def self.fix_name(name)
      return self.flip_word_order(self.simplify_name(name))
    end
    
    def self.flip_word_order(word)
      # e.g., change 'English, Old' to 'Old English'
      return word.gsub(/([^\,\;]+)[[:space:]]*[\,\;]+[[:space:]]*([^\,\;]+)/,'\\2 \\1').strip()
    end
    
    def load_file(filepath,id=self.class.get_class_name(self))
      y = YAML.load_file(filepath)
      @values.merge!(y[id])
      
      return self
    end
    
    def save_file(filepath,id=self.class.get_class_name(self))
      File.open(filepath,'w') do |f|
        v = {}
        v[id] = @values
        YAML.dump(v,f)
      end
    end
    
    def self.simplify_code(code)
      # e.g., remove 'US-' from 'US-AL'
      return code.gsub(/[[:alnum:][:space:]]+\-[[:space:]]*/,'').strip()
    end
    
    def self.simplify_name(name)
      # e.g., remove '(the)' from 'United States of America (the)'
      return name.gsub(/[[:space:]]*\([^\)]*\)[[:space:]]*/,'').strip()
    end
    
    def sort_keys!()
      # Old way: @values = @values.sort().to_h()
      
      new_values = {}
      
      @values.keys().sort().each() do |code|
        new_values[code] = @values[code]
      end
      
      @values = new_values
      return self
    end
    
    def [](code)
      @values[code]
    end
    
    def []=(code,value)
      @values[code] = value
    end
    
    def self.get_class_name(class_var)
      return class_var.class.name.split('::').last
    end
    
    def key?(code)
      @values.key?(code)
    end
    
    def to_s()
      s = ''
      
      @values.each() do |code,value|
        s << "#{code}: #{value}\n"
      end
      
      return s
    end
  end
end
