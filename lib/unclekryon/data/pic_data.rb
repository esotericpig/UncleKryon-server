#!/usr/bin/env ruby

require 'yaml'

module UncleKryon
  class PicData
    attr_accessor :id
    attr_accessor :url
    
    def initialize
      @id = 0
      @url = ''
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      return s
    end
  end
end
