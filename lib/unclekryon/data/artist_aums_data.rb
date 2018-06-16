#!/usr/bin/env ruby

###
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2018 Jonathan Bradley Whited (@esotericpig)
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

require 'unclekryon/util'

require 'unclekryon/data/base_data'
require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/kryon_aum_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/release_data'

###
# Don't extend BaseData, as updated_aums_on is stored in ArtistData.
###
module UncleKryon
  class ArtistAumsData
    attr_accessor :releases
    attr_accessor :albums
    attr_accessor :aums
    attr_accessor :pics
    
    def initialize()
      super()
      
      @releases = {}
      @albums = {}
      @aums = {}
      @pics = {}
    end
    
    def self.load_file(filepath)
      filedata = YAML.load_file(filepath) if File.exist?(filepath)
      filedata = {} if !filedata
      
      artist_aums = ArtistAumsData.new()
      Util.hash_def(filedata,['ArtistAums'],{})
      artist_aums.releases = Util.hash_def(filedata,['ArtistAums','Releases'],artist_aums.releases)
      artist_aums.albums = Util.hash_def(filedata,['ArtistAums','Albums'],artist_aums.albums)
      artist_aums.aums = Util.hash_def(filedata,['ArtistAums','Aums'],artist_aums.aums)
      artist_aums.pics = Util.hash_def(filedata,['ArtistAums','Pics'],artist_aums.pics)
      
      return artist_aums
    end
    
    def save_to_file(filepath,**options)
      raise "Empty filepath: #{filepath}" if filepath.nil?() || (filepath = filepath.strip()).empty?()
      
      filedata = {'ArtistAums'=>{}}
      filedata['ArtistAums']['Releases'] = @releases
      filedata['ArtistAums']['Albums'] = @albums
      filedata['ArtistAums']['Aums'] = @aums
      filedata['ArtistAums']['Pics'] = @pics
      
      Util.mk_dirs_from_filepath(filepath)
      File.open(filepath,'w') do |f|
        YAML.dump(filedata,f)
      end
    end
    
    def max_updated_on()
      max = nil
      max = Util.safe_max(max,BaseData.max_updated_on(@releases))
      max = Util.safe_max(max,BaseData.max_updated_on(@albums))
      max = Util.safe_max(max,BaseData.max_updated_on(@aums))
      max = Util.safe_max(max,BaseData.max_updated_on(@pics))
      
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
      s << "- Aums:\n"
      @aums.each() do |k,v|
        s << "  - #{v.to_s()}\n"
      end
      s << "- Pics:\n"
      @pics.each() do |k,v|
        s << "  - #{v.to_s()}\n"
      end
      
      return s
    end
  end
end
