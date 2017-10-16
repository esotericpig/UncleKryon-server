#!/usr/bin/env ruby

module UncleKryon
  class ArtistData
    attr_accessor :releases
    attr_accessor :albums
    attr_accessor :aums
    attr_accessor :pics
    
    def initialize
      @releases = {}
      @albums = {}
      @aums = {}
      @pics = {}
    end
  end
end
