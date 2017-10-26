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

require 'nokogiri'
require 'open-uri'

require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/kryon_aum_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/time_data'

require 'unclekryon/util'

module UncleKryon
  class KryonAumYearAlbumParser
    attr_accessor :artist
    attr_accessor :url
    
    def parse_site(artist,url)
      @local_dump = {'aum_title'=>[],'aum_time'=>[],'aum_size'=>[]}
      
      @artist = artist
      @url = url
      
      # Force 'utf-8' (see charset "X-MAC-ROMAN" in 2017 "The Discovery Series")
      doc = Nokogiri::HTML(open(url),nil,'utf-8')
      
      id = Util::gen_id(url)
      album = artist.albums[id]
      
      if album.nil?
        album = KryonAumAlbumData.new
        album.id = id
        album.url = url
        
        artist.albums[id] = album
      end
      
      parse_dump(doc,album) # Must be first because other methods rely on dump
      parse_pics(doc,album)
      parse_aums(doc,album)
      
      album.fill_empty_data()
      
      return album
    end
    
    def parse_aums(doc,album)
      links = doc.css('a')
      
      return if links.nil?
      
      i = 0 # Don't do #each_with_index() because sometimes we next
      
      links.each do |link|
        next if link.nil?
        
        href = link['href']
        
        next if href.nil? || href.empty?
        next if href !~ /\.mp3/i
        
        aum = KryonAumData.new
        aum.url = Util::clean_data(href)
        aum.id = Util::gen_id(aum.url)
        aum.filename = Util::parse_url_filename(aum.url)
        
        r = Util::get_url_header_data(aum.url)
        aum.size = r['content-length']
        aum.size = aum.size[0] if aum.size.is_a?(Array)
        
        if i < @local_dump['aum_title'].length
          aum.title = @local_dump['aum_title'][i]
        end
        if i < @local_dump['aum_time'].length
          aum.time = @local_dump['aum_time'][i]
        end
        if (!aum.size || aum.size.empty?) && i < @local_dump['aum_size'].length
          aum.size = @local_dump['aum_size'][i]
        end
        
        i += 1
        
        album.aum_ids.push(aum.id)
        @artist.aums[aum.id] = aum
      end
    end
    
    def parse_dump(doc,album)
      album.dump = []
      tds = doc.css('td')
      
      return if tds.nil?
      
      # Keep "NOTE:" for now (could be good for desc?)
      exclude_content_regex = /
        CLICK[[:space:]]*THE[[:space:]]*MP3|
        INSTRUCTIONS\:|
        INTERNET[[:space:]]*CONNECTION|
        KRYON[[:space:]]*CHANNELLING|
        These[[:space:]]*MP3[[:space:]]*files|
        This[[:space:]]*MP3[[:space:]]*file|
        WHAT[[:space:]]*TO[[:space:]]*DO\:|
        YOU[[:space:]]*NEED[[:space:]]*A[[:space:]]*GOOD|
        (.+\.mp3\z)
      /ix
      
      first_title_regex = /
        MINI|
        WELCOME[[:space:]]+MEETING|
        WELCOME[[:space:]]+DINNER|
        [[:space:]]+ONE\"?[[:space:]]*\z| #" gedit hack
        [[:space:]]+1\"?[[:space:]]*\z| #" gedit hack
        Abbey[[:space:]]+of[[:space:]]+San[[:space:]]+Galgano|
        Part[[:space:]]+one|
        On[[:space:]]+the[[:space:]]+mountain|
        Tripple[[:space:]]+Falls[[:space:]]+\-[[:space:]]+DuPont[[:space:]]+State[[:space:]]+Forest|
        \A[[:space:]]*SATURDAY[[:space:]]*\z|
        Marilyn[[:space:]]+Harper[[:space:]]+\&[[:space:]]+Lee[[:space:]]+Carroll|
        Day[[:space:]]+one|
        OPENING[[:space:]]*\z|
        Dual[[:space:]]+Channelling[[:space:]]+\-[[:space:]]+|
        Salt[[:space:]]+mine[[:space:]]+\(second[[:space:]]+group\)|
        Porto[[:space:]]+\-[[:space:]]+End[[:space:]]+of[[:space:]]+Fatima[[:space:]]+Channeling|
        DHARAMSHALA\-KANGRA[[:space:]]+FORT
      /ix
      exclude_title_regex = /
        KRYON[[:space:]]+.*CHANNELLING|
        KRYON[[:space:]]+\&|
        ENTIRE[[:space:]]+PANEL[[:space:]]+RECORDING|
        KRYON[[:space:]]+EGYPT[[:space:]]+TOUR[[:space:]]+1
      /ix
      
      # 2017 "Petra, Jordan (5)" has a ":" in the megabytes cell
      size_regex = /\A[[:space:]]*[[:digit:]]+(\.|\:|[[:digit:]]|[[:space:]])*megabytes[[:space:]]*\z/i
      time_regex = /\A[[:space:]]*[[:digit:]]+(\:|[[:digit:]]|[[:space:]])*(minutes)?[[:space:]]*\z/i
      
      found_aum_title = false
      
      tds.each do |td|
        next if td.nil?
        next if td.content.nil?
        
        orig_c = td.content
        c = Util::clean_data(orig_c)
        
        next if c.empty?
        next if c =~ exclude_content_regex
        
        add_to_dump = true
        
        if c =~ time_regex
          @local_dump['aum_time'].push(TimeData.new(c).to_s)
          add_to_dump = false
        elsif c =~ size_regex
          @local_dump['aum_size'].push(c)
          add_to_dump = false
        elsif (found_aum_title || c =~ first_title_regex) && c !~ exclude_title_regex
          @local_dump['aum_title'].push(Util::fix_shortwith_text(c))
          found_aum_title = true
        end
        
        if add_to_dump
          album.dump.push(c)
          
          # For now, don't do this; if the font size is big, it's bad for mobile anyway
          #album.dump.push(Util::clean_data(td.to_s)) # For bold, etc. html
        end
      end
    end
    
    def parse_pics(doc,album)
      imgs = doc.css('img')
      
      return if imgs.nil?
      
      exclude_imgs = /
        buttonMP3\.png|
        freedownloadtype\.gif|
        handani\.gif|
        Kryonglobe\.jpg|
        MP3\-download\.jpg|
        MP3\-graphic\(SM\)\.jpg|
        NavMenu\_AUDIOmaster\.png|
        NavMenu\_master\.png|
        testimonials\.png
      /ix
      
      imgs.each do |img|
        next if img.nil?
        
        src = img['src']
        
        next if src.nil? || src.empty?
        next if src =~ exclude_imgs
        
        pic = PicData.new
        pic.url = Util::clean_link(url,src)
        pic.id = Util::gen_id(pic.url)
        
        album.pic_ids.push(pic.id)
        @artist.pics[pic.id] = pic
      end
    end
  end
end
