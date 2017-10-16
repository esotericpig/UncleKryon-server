#!/usr/bin/env ruby

require 'yaml'

module UncleKryon
  class ReleaseData
    attr_accessor :title
    attr_accessor :url
    attr_accessor :album_ids
    
    def initialize
      @title = ''
      @url = ''
      @album_ids = []
    end
    
    def to_s(artist=nil)
      s = self.to_yaml()
      
      if !artist.nil?
        @album_ids.each do |album_id|
          album = artist.albums[album_id]
          s += (!album.nil?) ? album.to_s(artist) : "ERROR: #{album_id} is nil!"
        end
      end
      
      return s
    end
  end
end
