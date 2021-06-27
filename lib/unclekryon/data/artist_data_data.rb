#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2021 Jonathan Bradley Whited
#
# SPDX-License-Identifier: GPL-3.0-or-later
#++


require 'yaml'

require 'unclekryon/util'

require 'unclekryon/data/album_data'
require 'unclekryon/data/aum_data'
require 'unclekryon/data/base_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/release_data'

###
# Don't extend BaseData, as updated_aums_on is stored in ArtistData.
###
module UncleKryon
  class ArtistDataData
    ID = 'ArtistData'
    RELEASES_ID = 'Releases'
    ALBUMS_ID = 'Albums'
    AUMS_ID = 'Aums'
    SCROLLS_ID = 'Scrolls'
    VISIONS_ID = 'Visions'
    PICS_ID = 'Pics'

    attr_accessor :releases
    attr_accessor :albums
    #attr_accessor :aums
    #attr_accessor :scrolls
    #attr_accessor :visions
    #attr_accessor :pics

    def initialize()
      super()

      @releases = {}
      @albums = {}
      #@aums = {}
      #@scrolls = {}
      #@visions = {}
      #@pics = {}
    end

    def self.load_file(filepath)
      filedata = YAML.load_file(filepath) if File.exist?(filepath)
      filedata = {} if !filedata

      artist = ArtistDataData.new()
      Util.hash_def(filedata,[ID],{})
      artist.releases = Util.hash_def(filedata,[ID,RELEASES_ID],artist.releases)
      artist.albums = Util.hash_def(filedata,[ID,ALBUMS_ID],artist.albums)
      #artist.aums = Util.hash_def(filedata,[ID,AUMS_ID],artist.aums)
      #artist.scrolls = Util.hash_def(filedata,[ID,SCROLLS_ID],artist.scrolls)
      #artist.visions = Util.hash_def(filedata,[ID,VISIONS_ID],artist.visions)
      #artist.pics = Util.hash_def(filedata,[ID,PICS_ID],artist.pics)

      return artist
    end

    def save_to_file(filepath,**options)
      raise "Empty filepath: #{filepath}" if filepath.nil?() || (filepath = filepath.strip()).empty?()

      filedata = {ID=>{}}
      filedata[ID][RELEASES_ID] = @releases
      filedata[ID][ALBUMS_ID] = @albums
      #filedata[ID][AUMS_ID] = @aums
      #filedata[ID][SCROLLS_ID] = @scrolls
      #filedata[ID][VISIONS_ID] = @visions
      #filedata[ID][PICS_ID] = @pics

      Util.mk_dirs_from_filepath(filepath)
      File.open(filepath,'w') do |f|
        YAML.dump(filedata,f)
      end
    end

    def max_updated_on()
      max = nil
      max = Util.safe_max(max,BaseData.max_updated_on(@releases))
      max = Util.safe_max(max,BaseData.max_updated_on(@albums))
      #max = Util.safe_max(max,BaseData.max_updated_on(@aums))
      #max = Util.safe_max(max,BaseData.max_updated_on(@scrolls))
      #max = Util.safe_max(max,BaseData.max_updated_on(@visions))
      #max = Util.safe_max(max,BaseData.max_updated_on(@pics))

      return Util.format_datetime(max)
    end

    def to_mini_s()
      return to_s(true)
    end

    def to_s(mini=false)
      s = ''

      s << "- Releases:\n"
      @releases.each() do |k,v|
        s << "  - " << v.to_s(mini).gsub("\n","\n    ") << "\n"
      end
      s << "- Albums:\n"
      @albums.each() do |k,v|
        s << "  - " << v.to_s(mini).gsub("\n","\n    ") << "\n"
      end

      #s << "- Aums:\n"
      #@aums.each() do |k,v|
      #  s << "  - #{v.to_s()}\n"
      #end
      #s << "- Scrolls:\n"
      #@scrolls.each() do |k,v|
      #  s << "  - #{v.to_s()}\n"
      #end
      #s << "- Visions:\n"
      #@visions.each() do |k,v|
      #  s << "  - #{v.to_s()}\n"
      #end
      #s << "- Pics:\n"
      #@pics.each() do |k,v|
      #  s << "  - #{v.to_s()}\n"
      #end

      return s
    end
  end
end
