#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2019 Jonathan Bradley Whited (@esotericpig)
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


require 'nokogiri'
require 'open-uri'

require 'unclekryon/dev_opts'
require 'unclekryon/iso'
require 'unclekryon/log'
require 'unclekryon/trainer'
require 'unclekryon/util'

require 'unclekryon/data/album_data'
require 'unclekryon/data/aum_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/timespan_data'

module UncleKryon
  class KryonAumYearAlbumParser
    include Logging
    
    attr_accessor :album
    attr_accessor :artist
    attr_accessor :options
    attr_accessor :trainers
    attr_accessor :training
    attr_accessor :updated_on
    attr_accessor :url
    
    alias_method :training?,:training
    
    def initialize(artist=nil,url=nil,album: nil,training: false,train_filepath: nil,updated_on: nil,
          **options)
      @album = album
      @artist = artist
      @options = options
      @updated_on = Util.format_datetime(DateTime.now()) if Util.empty_s?(updated_on)
      @url = url
      
      @trainers = Trainers.new(train_filepath)
      @training = training
      
      @trainers['aum_year_album'] = Trainer.new({
          'alds'=>'album_dates',
          'altt'=>'album_title',
          'allo'=>'album_locations',
          'almi'=>'album_mini_desc',
          'alma'=>'album_main_desc',
          'aust'=>'aum_subtitle',
          'aulg'=>'aum_languages', # See 2018 "Montreal QB w/Robert Coxon (3)" aums' subtitles "FRENCH"
          'autt'=>'aum_title',
          'autm'=>'aum_timespan',
          'ausz'=>'aum_filesize',
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
      
      # URLs that return 404 or are empty; fix by hand
      exclude_urls = /
        awakeningzone\.com\/Episode\.aspx\?EpisodeID\=|
        www\.talkshoe\.com\/talkshoe\/web\/audioPop\.jsp\?episodeId\=
      /ix
      
      if @url =~ exclude_urls
        log.warn("Excluding Album URL #{@url}")
        return
      end
      
      @trainers.load_file()
      
      raise ArgumentError,"Artist cannot be nil" if @artist.nil?()
      raise ArgumentError,"URL cannot be empty" if @url.nil?() || (@url = @url.strip()).empty?()
      
      # Album data (flags are okay) should never go in this, only for aums, pics, etc.
      @local_dump = {
          :album_dates=>false,
          :album_title=>false,
          :album_locations=>false,
          :album_mini_desc=>false,
          :album_main_desc=>false,
          :aums=>0,
          :aum_subtitle=>[],
          :aum_languages=>[],
          :aum_title=>[],
          :aum_timespan=>[],
          :aum_filesize=>[],
          :aum_filename=>[]
        }
      
      # Force 'utf-8'
      # - See charset "X-MAC-ROMAN" in 2017 "The Discovery Series", 2016 "Kryon in Budapest (5)"
      doc = Nokogiri::HTML(open(@url),nil,'utf-8')
      
      old_album = @artist.albums[@url]
      
      @album = old_album.clone()
      @album.updated_on = @updated_on
      @album.url = @url
      
      if old_album.nil?()
        @artist.albums[@url] = @album
      end
      
      parse_dump(doc,@album) # Must be first because other methods rely on @local_dump
      
      return @album if @training # Currently, no other training occurs
      
      parse_pics(doc,@album)
      parse_aums(doc,@album)
      
      if @album == old_album
        @album.updated_on = old_album.updated_on
      end
      
      @artist.albums[@url] = @album
      
      return @album
    end
    
    def parse_aums(doc,album)
      links = doc.css('a')
      
      return if links.nil?
      
      i = 0 # Don't do #each_with_index() because sometimes we next
      
      links.each do |link|
        next if link.nil?
        
        audio_file_regex = /\.mp3/i
        href = link['href']
        exclude_links = /
          files\.kryonespanol\.com\/audio\/
        /ix
        
        next if href.nil? || href.empty?
        next if href !~ audio_file_regex
        next if href =~ exclude_links
        
        aum = AumData.new
        aum.url = Util.clean_data(href)
        aum.filename = Util.parse_url_filename(aum.url)
        aum.updated_on = @updated_on
        
        if aum.url =~ /\A\.\.?\//
          aum.url = Util.clean_link(@url,aum.url)
        end
        
        # Filesize
        if !DevOpts.instance.test?()
          # Getting header data is slow, so only do it when not testing
          begin
            r = Util.get_url_header_data(aum.url)
            aum.filesize = r['content-length']
            aum.filesize = aum.filesize[0] if aum.filesize.is_a?(Array)
          rescue => e
            raise e.exception("#{e.message}; couldn't get header data for #{aum.url}")
          end
        end
        
        # Subtitle
        if i < @local_dump[:aum_subtitle].length
          aum.subtitle = @local_dump[:aum_subtitle][i]
        else
          log.warn("No subtitle for: #{aum.filename},#{aum.url}")
        end
        
        # Languages
        aum.languages = @local_dump[:aum_languages][i] if i < @local_dump[:aum_languages].length
        
        # Title
        if i < @local_dump[:aum_title].length
          aum.title = @local_dump[:aum_title][i]
        else
          # Set title to something at least
          if !(afn = aum.filename).nil?() && !afn.strip().empty?()
            # More descriptive than subtitle
            aum.title = afn.gsub(audio_file_regex,'').strip()
            log.warn("Using filename as title: #{aum.title}")
          else
            aum.title = aum.subtitle
            log.warn("Using subtitle as title: #{aum.title}")
          end
        end
        
        # Timespan
        if i < @local_dump[:aum_timespan].length
          aum.timespan = @local_dump[:aum_timespan][i]
        else
          msg = "No timespan for: #{aum.title},#{aum.subtitle},#{aum.filename},#{aum.url}"
          
          log.warn(msg)
          
          #if DevOpts.instance.dev?()
          #  raise "#{msg}:\n#{@local_dump}\n#{album.dump}"
          #else
          #  log.warn(msg)
          #end
        end
        
        # Filesize, if not set
        if (aum.filesize.nil?() || aum.filesize.strip().empty?) && i < @local_dump[:aum_filesize].length
          aum.filesize = @local_dump[:aum_filesize][i]
          log.warn("Using local dump filesize: #{aum.filesize}")
        end
        
        i += 1
        
        # Is it old?
        if album.aums.key?(aum.url) && aum == album.aums[aum.url]
          aum.updated_on = album.aums[aum.url].updated_on
        else # New
          album.updated_on = @updated_on
        end
        
        album.aums[aum.url] = aum
      end
    end
    
    def parse_dump(doc,album)
      album.dump = []
      tds = doc.css('td')
      
      return if tds.nil?
      
      filename_regex = /\.mp3[[:space:]]*\z/i
      # 2017 "Petra, Jordan (5)" has a ":" in the megabytes cell
      size_regex = /\A[[:space:]]*[[:digit:]]+(\.|\:|[[:digit:]]|[[:space:]])*megabytes[[:space:]]*\z/i
      # 2017 "Monument Valley Tour (11)" has a "." in the minutes cell
      # 2017 "SUMMER LIGHT CONFERENCE PANEL (1)" is a special case ("One hour 6 minutes - (66 minutes)")
      time_regex = /
        \A[[:space:]]*[[:digit:]]+(\:|\.|[[:digit:]]|[[:space:]])*(minutes|Min)[[:space:]]*\z|
        \([[:space:]]*[[:digit:]]+[[:space:]]+minutes[[:space:]]*\)[[:space:]]*\z
      /ix
      # 2017 "KRYON INDIA-NEPAL TOUR PART 1 (10)" doesn't have the word "megabytes"
      time_or_size_regex = /\A[[:space:]]*[[:digit:]]+(\:|\.|[[:digit:]]|[[:space:]])*\z/i
      # 2015 ones have a lot of "13:12 Min - 15.9 megs"
      time_and_size_regex = /\A[[:space:]]*[[:digit:]]+[\:\.][[:digit:]]+[[:space:]]+Min[[:space:]]+\-[[:space:]]+[[:digit:]]+\.?[[:digit:]]*[[:space:]]*megs/i
      
      size_count = 0
      time_count = 0
      
      tds.each do |td|
        next if td.nil?
        next if td.content.nil?
        
        orig_c = Util.clean_charset(td.content)
        c = Util.clean_data(orig_c)
        
        next if c.empty?
        #if c =~ exclude_content_regex
        #  log.warn("Excluding content: #{c}")
        #  next
        #end
        
        add_to_dump = true
        
        if c =~ time_regex
          @local_dump[:aum_timespan].push(TimespanData.new(c).to_s())
          add_to_dump = false
          time_count += 1
        elsif c =~ size_regex
          @local_dump[:aum_filesize].push(c)
          add_to_dump = false
          size_count += 1
        elsif c =~ time_or_size_regex
          # Time is usually before size
          if time_count == size_count
            @local_dump[:aum_timespan].push(TimespanData.new(c).to_s())
            time_count += 1
          else
            @local_dump[:aum_filesize].push(c)
            size_count += 1
          end
          
          add_to_dump = false
        elsif c =~ time_and_size_regex
          time_and_size = c.split(/[[:space:]]*\-[[:space:]]*/) # Split on '-'
          
          @local_dump[:aum_timespan].push(TimespanData.new(time_and_size[0]).to_s())
          time_count += 1
          @local_dump[:aum_filesize].push(time_and_size[1])
          size_count += 1
          
          add_to_dump = false
        elsif c =~ filename_regex
          @local_dump[:aums] += 1
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
              #has_header = @local_dump[:album_title] || @local_dump[:album_dates] ||
              #  @local_dump[:album_locations] || @local_dump[:album_mini_desc] || @local_dump[:album_main_desc]
              has_header = true
              tag = @trainers['aum_year_album'].tag(par)
              
              # For 2017 "RETURN TO LEMURIA (7)"
              if par =~ /\A[[:space:]]*MEDITATION[[:space:]]+-[[:space:]]+Kalei[[:space:]]+-[[:space:]]+John[[:space:]]+-[[:space:]]+Amber[[:space:]]*\z/i
                tag = 'aum_title'
                log.warn("Changing tag to aum_title: #{Util.clean_data(par)}")
              end
              
              case tag
              when 'album_title'
                if !@local_dump[:album_title]
                  @local_dump[:album_title] = true
                end
              when 'album_dates'
                if !@local_dump[:album_dates]
                  @local_dump[:album_dates] = true
                end
              when 'album_locations'
                if !@local_dump[:album_locations]
                  @local_dump[:album_locations] = true
                end
              when 'album_mini_desc'
                par.split(/\n+/).each() do |p|
                  p = Util.clean_data(p)
                  
                  if !p.empty?()
                    case @trainers['aum_year_album_mini_desc'].tag(p)
                    when 'desc'
                      if !@local_dump[:album_mini_desc]
                        @local_dump[:album_mini_desc] = true
                        album.mini_desc = p
                      else
                        album.mini_desc << ' | ' if !album.mini_desc.strip().empty?()
                        album.mini_desc << p
                      end
                    when 'ignore'
                      log.warn("Excluding mini desc content: #{p}")
                    end
                  end
                end
                
                add_to_dump = false
              when 'album_main_desc'
                if !@local_dump[:album_main_desc]
                  @local_dump[:album_main_desc] = true
                  album.main_desc = ''.dup()
                else
                  album.main_desc << "\n\n" if !album.main_desc.strip().empty?()
                end
                
                par.split(/\n+/).each() do |p|
                  album.main_desc << Util.clean_data(p) << "\n"
                end
                
                album.main_desc = album.main_desc.strip() # Remove last newline
                add_to_dump = false
              when 'ignore'
                log.warn("Excluding content: #{Util.clean_data(par)}")
                add_to_dump = false
              else
                if !has_header
                  log.warn("No header yet so ignoring: #{Util.clean_data(par)}")
                else
                  case tag
                  when 'aum_subtitle'
                    @local_dump[:aum_subtitle].push(Util.clean_data(par))
                    add_to_dump = false
                  when 'aum_languages'
                    p = Util.clean_data(par)
                    @local_dump[:aum_languages].push(Iso.languages.find_by_kryon(p))
                    @local_dump[:aum_subtitle].push(p)
                    add_to_dump = false
                  when 'aum_title'
                    @local_dump[:aum_title].push(Util.clean_data(par))
                    
                    # Special case for 2017 "LISBON, PORTUGAL (Fatima Tour) (3)"
                    if par =~ /\A[[:space:]]*Lisbon[[:space:]]+Channeling[[:space:]]+1[[:space:]]*\z/i
                      @local_dump[:aum_title].push('Lisbon Channeling 2');
                      @local_dump[:aum_title].push('Lisbon Channeling 3');
                      log.warn("Adding aum_titles for: #{Util.clean_data(par)}")
                    end
                    # For 2017 "KRYON INDIA-NEPAL TOUR PART 1 (10)" & "KRYON INDIA-NEPAL TOUR PART 2 (8)"
                    if par =~ /\A[[:space:]]*PAGE[[:space:]]*(ONE|TWO)[[:space:]]*\z/i
                      p = @local_dump[:aum_title].pop()
                      log.warn("Ignoring aum title: #{p}")
                    end
                    
                    add_to_dump = false
                  when 'aum_filename'
                    add_to_dump = false
                  end
                end
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
        
        pic = PicData.new()
        
        pic.url = Util.clean_link(url,src)
        pic.filename = Util.parse_url_filename(pic.url)
        
        pic.alt = img['alt']
        pic.alt = '' if Util.empty_s?(pic.alt)
        pic.caption = ''
        
        pic.name = Util.empty_s?(pic.alt) ? File.basename(pic.filename,File.extname(pic.filename)) : pic.alt
        pic.updated_on = @updated_on
        
        # Is it old?
        if album.pics.key?(pic.url) && pic == album.pics[pic.url]
          pic.updated_on = album.pics[pic.url].updated_on
        else # New
          album.updated_on = @updated_on
        end
        
        album.pics[pic.url] = pic
      end
    end
  end
end
