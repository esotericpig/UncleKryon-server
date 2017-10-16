#!/usr/bin/env ruby

require 'yaml'

module UncleKryon
  class KryonAumData
    attr_accessor :id
    attr_accessor :title
    attr_accessor :time
    attr_accessor :size
    attr_accessor :filename
    attr_accessor :url
    
    def initialize
      @id = 0
      @title = ''
      @time = ''
      @size = ''
      @filename = ''
      @url = ''
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      return s
    end
  end
end
