#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'

require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/kryon_aum_data'
require 'unclekryon/data/pic_data'

require 'unclekryon/util'

module UncleKryon
  class KryonAumYearAlbumParser
    attr_accessor :artist
    attr_accessor :url
    
    def parse_site(artist,url)
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
      
      parse_dump(doc,album)
      parse_pics(doc,album)
      parse_aums(doc,album)
      
      return album
    end
    
    def parse_dump(doc,album)
      album.dump = []
      tds = doc.css('td')
      
      return if tds.nil?
      
      # Keep "NOTE:" for now (could be good for desc?)
      exclude_content = /
        CLICK[[:space:]]*THE[[:space:]]*MP3|
        INSTRUCTIONS\:|
        INTERNET[[:space:]]*CONNECTION|
        KRYON[[:space:]]*CHANNELLING|
        These[[:space:]]*MP3[[:space:]]*files|
        This[[:space:]]*MP3[[:space:]]*file|
        WHAT[[:space:]]*TO[[:space:]]*DO\:|
        YOU[[:space:]]*NEED[[:space:]]*A[[:space:]]*GOOD
      /ix
      
      tds.each do |td|
        next if td.nil?
        next if td.content.nil?
        
        c = Util::clean_data(td.content)
        
        next if c.empty?
        next if c =~ exclude_content
        
        album.dump.push(c)
      end
    end
    
    def parse_aums(doc,album)
      links = doc.css('a')
      
      return if links.nil?
      
      links.each do |link|
        next if link.nil?
        
        href = link['href']
        
        next if href.nil? || href.empty?
        next if href !~ /\.mp3/i
        
        aum = KryonAumData.new
        aum.url = Util::clean_data(href)
        aum.id = Util::gen_id(aum.url)
        aum.filename = Util::parse_url_filename(aum.url)
        
        # Currently, too slow
        #r = Util::get_url_content_data(aum.url)
        #aum.size = r['length']
        
        album.aum_ids.push(aum.id)
        @artist.aums[aum.id] = aum
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
