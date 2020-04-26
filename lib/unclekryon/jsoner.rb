#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2020 Jonathan Bradley Whited (@esotericpig)
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
# along with UncleKryon-server.  If not, see <https://www.gnu.org/licenses/>.
#++


IS_SCRIPT = $0 == __FILE__

if IS_SCRIPT
  require 'rubygems'
  require 'bundler/setup'
end

require 'json'
require 'yaml'

require 'unclekryon/iso'
require 'unclekryon/util'

require 'unclekryon/data/artist_data'
require 'unclekryon/data/artist_data_data'

module UncleKryon
  class Jsoner
    def jsonify_all(pretty=false)
      json = {}
      
      #jsonify_iso(json)
      jsonify_artists(json)
      
      return pretty ? JSON.pretty_generate(json) : json.to_json()
    end
    
    def jsonify_artists(json)
      json['aum'] = {}
      json['scroll'] = {}
      json['vision'] = {}
      json['pic'] = {}
      
      kryon = to_hash(ArtistData.load_file(File.join('hax','kryon.yaml')))
      
      kryon['release'] = {}
      kryon['album'] = {}
      
      jsonify_artist_data(json,kryon,File.join('hax','kryon_aums_2002-2005.yaml'))
      
      json['artist'] = {
        kryon['id'] => kryon
      }
    end
    
    def jsonify_artist_data(json,artist,file)
      data = ArtistDataData.load_file(file)
      
      data.albums.each() do |album_id,album|
        album.aums.each() do |aum_id,aum|
          json[ArtistDataData::AUMS_ID][aum_id] = to_hash(aum)
        end
        album.aums = album.aums.keys
        
        album.pics.each() do |pic_id,pic|
          json[ArtistDataData::PICS_ID][pic_id] = to_hash(pic)
        end
        album.pics = album.pics.keys
      end
      
      artist[ArtistDataData::ALBUMS_ID] = to_hash(data.albums)
      
      #attr_accessor :scrolls
      #attr_accessor :visions
    end
    
    def jsonify_iso(json)
      json['iso'] = to_hash(Iso.iso)
      json['can_proter'] = to_hash(Iso.can_provs_terrs.values)
      json['country'] = to_hash(Iso.countries.values)
      json['language'] = to_hash(Iso.languages.values)
      json['region'] = to_hash(Iso.regions.values)
      json['subregion'] = to_hash(Iso.subregions.values)
      json['usa_state'] = to_hash(Iso.usa_states.values)
    end
    
    def to_hash(obj)
      hash = {}
      
      if obj.respond_to?(:instance_variables) && obj.instance_variables.length > 0
        obj.instance_variables.each() do |var|
          hash[var.to_s().delete('@')] = to_hash(obj.instance_variable_get(var))
        end
      elsif obj.is_a?(Hash)
        obj.each() do |k,v|
          hash[k] = to_hash(v)
        end
      else
        return Util.empty_s?(obj.to_s()) ? nil : obj
      end
      
      return hash
    end
  end
end

if IS_SCRIPT
  j = UncleKryon::Jsoner.new()
  
  puts j.jsonify_all(true)
end
