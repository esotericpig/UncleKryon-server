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

require 'nokogiri'
require 'open-uri'

require 'unclekryon/iso'
require 'unclekryon/log'
require 'unclekryon/trainer'
require 'unclekryon/util'

require 'unclekryon/data/kryon_aum_album_data'
require 'unclekryon/data/kryon_aum_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/time_data'

module UncleKryon
  class KryonAumYearAlbumParser
    include Logging
    
    attr_accessor :album
    attr_accessor :artist
    attr_accessor :options
    attr_accessor :trainers
    attr_accessor :training
    attr_accessor :url
    
    alias_method :training?,:training
    
    def initialize(artist=nil,url=nil,album: nil,training: false,train_filepath: nil,**options)
      @album = album
      @artist = artist
      @options = options
      @url = url
      
      @trainers = Trainers.new(train_filepath)
      @training = training
      
      @trainers['aum_year_album'] = Trainer.new({
          'altt'=>'album_title',
          'alds'=>'album_dates',
          'allo'=>'album_location',
          'almi'=>'album_mini_desc',
          'alma'=>'album_main_desc',
          'aust'=>'aum_subtitle',
          'aulg'=>'aum_language', # See 2018 "Montreal QB w/Robert Coxon (3)" aums' subtitles "FRENCH"
          'autt'=>'aum_title',
          'autm'=>'aum_time',
          'ausz'=>'aum_size',
          'aufn'=>'aum_filename',
          'audu'=>'dump',
          'i'   =>'ignore'
        })
      @trainers['aum_year_album_mini_desc'] = Trainer.new({
          'd'=>'date',
          'l'=>'location',
          's'=>'desc',
          'i'=>'ignore'
        })
    end
    
    def parse_site(artist=nil,url=nil)
      @artist = artist unless artist.nil?()
      @url = url unless url.nil?()
      
      @trainers.load_file()
      
      raise ArgumentError,"Artist cannot be nil" if @artist.nil?()
      raise ArgumentError,"URL cannot be empty" if @url.nil?() || (@url = @url.strip()).empty?()
      
      # Album data (flags are okay) should never go in this, only for aums, pics, etc.
      @local_dump = {
          :album_mini_desc=>true,
          :album_main_desc=>true,
          :aum_subtitle=>[],
          :aum_language=>[],
          :aum_title=>[],
          :aum_time=>[],
          :aum_size=>[],
          :aum_filename=>[]
        }
      
      # Force 'utf-8' (see charset "X-MAC-ROMAN" in 2017 "The Discovery Series")
      doc = Nokogiri::HTML(open(@url),nil,'utf-8')
      
      id = Util.gen_id(@url)
      @album = @artist.albums[id]
      
      if @album.nil?
        @album = KryonAumAlbumData.new()
        @album.id = id
        @album.url = @url
        
        @artist.albums[id] = @album
      end
      
      parse_dump(doc,@album) # Must be first because other methods rely on @local_dump
      
      return @album if @training # Currently, no other training occurs
      
      parse_pics(doc,@album)
      parse_aums(doc,@album)
      
      @album.fill_empty_data()
      
      return @album
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
        aum.url = Util.clean_data(href)
        aum.id = Util.gen_id(aum.url)
        aum.filename = Util.parse_url_filename(aum.url)
        
        if !Log.instance.test?()
          # Getting header data is slow
          r = Util.get_url_header_data(aum.url)
          aum.size = r['content-length']
          aum.size = aum.size[0] if aum.size.is_a?(Array)
        end
        
        aum.subtitle = @local_dump[:aum_subtitle][i] if i < @local_dump[:aum_subtitle].length
        aum.language = @local_dump[:aum_language][i] if i < @local_dump[:aum_language].length
        aum.title = @local_dump[:aum_title][i] if i < @local_dump[:aum_title].length
        aum.time = @local_dump[:aum_time][i] if i < @local_dump[:aum_time].length
        
        if (aum.size.nil?() || aum.size.empty?) && i < @local_dump[:aum_size].length
          aum.size = @local_dump[:aum_size][i]
        end
        
        i += 1
        
        album.aum_ids.push(aum.id) if !album.aum_ids.include?(aum.id)
        @artist.aums[aum.id] = aum
      end
    end
    
    def parse_dump(doc,album)
      album.dump = []
      tds = doc.css('td')
      
      return if tds.nil?
      
      # Unfortunately, some things just have to be excluded the old fashioned way
      exclude_content_regex = /
        \A[[:space:]]*KRYON[[:space:]]+EGYPT[[:space:]]+TOUR[[:space:]]+1[[:space:]]*\z
      /x
      
      filename_regex = /\.mp3[[:space:]]*\z/i
      # 2017 "Petra, Jordan (5)" has a ":" in the megabytes cell
      size_regex = /\A[[:space:]]*[[:digit:]]+(\.|\:|[[:digit:]]|[[:space:]])*megabytes[[:space:]]*\z/i
      # 2017 "Monument Valley Tour (11)" has a "." in the minutes cell
      # 2017 "SUMMER LIGHT CONFERENCE PANEL (1)" is a special case ("One hour 6 minutes - (66 minutes)")
      time_regex = /
        \A[[:space:]]*[[:digit:]]+(\:|\.|[[:digit:]]|[[:space:]])*minutes[[:space:]]*\z|
        \([[:space:]]*[[:digit:]]+[[:space:]]+minutes[[:space:]]*\)[[:space:]]*\z
      /ix
      # 2017 " KRYON INDIA-NEPAL TOUR PART 1 (10)" doesn't have the word "megabytes"
      time_or_size_regex = /\A[[:space:]]*[[:digit:]]+(\:|\.|[[:digit:]]|[[:space:]])*\z/i
      
      size_count = 0
      time_count = 0
      
      tds.each do |td|
        next if td.nil?
        next if td.content.nil?
        
        orig_c = td.content
        c = Util.clean_data(orig_c)
        
        next if c.empty?
        if c =~ exclude_content_regex
          log.warn("Excluding content: #{c}")
          next
        end
        
        add_to_dump = true
        
        if c =~ time_regex
          @local_dump[:aum_time].push(TimeData.new(c).to_s())
          add_to_dump = false
          time_count += 1
        elsif c =~ size_regex
          @local_dump[:aum_size].push(c)
          add_to_dump = false
          size_count += 1
        elsif c =~ time_or_size_regex
          # Time is usually before size
          if time_count == size_count
            @local_dump[:aum_time].push(TimeData.new(c).to_s())
            time_count += 1
          else
            @local_dump[:aum_size].push(c)
            size_count += 1
          end
          
          add_to_dump = false
        elsif c =~ filename_regex
          add_to_dump = false
        else
          # Paragraphs
          pars = orig_c.gsub(/\A[[:space:]]+/,'').gsub(/[[:space:]]+\z/,'')
          pars = pars.split(/[\r\n\p{Zl}\p{Zp}]{2,}/)
          
          pars.each() do |par|
            par = par.gsub(/[[:blank:]]+/,' ').strip()
            par = Util.fix_shortwith_text(par)
            
            next if par.empty?()
            
            if @training
              if @trainers['aum_year_album'].train(par) == 'album_mini_desc'
                par.split(/\n+/).each() do |p|
                  @trainers['aum_year_album_mini_desc'].train(p)
                end
              end
            else
              tag = @trainers['aum_year_album'].tag(par)
              
              case tag
              when 'album_mini_desc'
                par.split(/\n+/).each() do |p|
                  p = Util.clean_data(p)
                  
                  if !p.empty?()
                    case @trainers['aum_year_album_mini_desc'].tag(p)
                    when 'desc'
                      if @local_dump[:album_mini_desc]
                        @local_dump[:album_mini_desc] = false
                        album.mini_desc = p
                      else
                        album.mini_desc << ' | ' if !album.mini_desc.empty?()
                        album.mini_desc << p
                      end
                    when 'ignore'
                      log.warn("Excluding mini desc content: #{p}")
                    end
                  end
                end
                
                add_to_dump = false
              when 'album_main_desc'
                if @local_dump[:album_main_desc]
                  @local_dump[:album_main_desc] = false
                  album.main_desc = ''
                else
                  album.main_desc << "\n" if !album.main_desc.empty?()
                end
                
                par.split(/\n+/).each() do |p|
                  album.main_desc << Util.clean_data(p) << "\n"
                end
                
                add_to_dump = false
              when 'aum_subtitle'
                @local_dump[:aum_subtitle].push(Util.clean_data(par))
                add_to_dump = false
              when 'aum_language'
                p = Util.clean_data(par)
                @local_dump[:aum_language].push(Iso.languages.find_by_kryon(p))
                @local_dump[:aum_subtitle].push(p)
                add_to_dump = false
              when 'aum_title'
                @local_dump[:aum_title].push(Util.clean_data(par))
                
                # Special case for 2017 "LISBON, PORTUGAL (Fatima Tour) (3)"
                if par =~ /\A[[:space:]]*Lisbon[[:space:]]+Channeling[[:space:]]+1[[:space:]]*\z/
                  @local_dump[:aum_title].push('Lisbon Channeling 2');
                  @local_dump[:aum_title].push('Lisbon Channeling 3');
                end
                
                add_to_dump = false
              when 'aum_filename'
                add_to_dump = false
              when 'ignore'
                log.warn("Excluding content: #{Util.clean_data(par)}")
                add_to_dump = false
              end
            end
          end
        end
        
        if add_to_dump
          album.dump.push(c)
          
          # For now, don't do this; if the font size is big, it's bad for mobile anyway
          #album.dump.push(Util.clean_data(td.to_s())) # For bold, etc. html
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
        if src =~ exclude_imgs
          log.warn("Excluding image: #{src}")
          next
        end
        
        pic = PicData.new
        pic.url = Util.clean_link(url,src)
        pic.id = Util.gen_id(pic.url)
        
        album.pic_ids.push(pic.id) if !album.pic_ids.include?(pic.id)
        @artist.pics[pic.id] = pic
      end
    end
  end
end
