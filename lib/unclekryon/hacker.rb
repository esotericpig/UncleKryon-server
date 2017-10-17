#!/usr/bin/env ruby

require 'bundler/setup'

require 'date'

require 'unclekryon/log'
require 'unclekryon/util'

require 'unclekryon/data/artist_data'

require 'unclekryon/parsers/kryon_aum_year_album_parser'
require 'unclekryon/parsers/kryon_aum_year_parser'

module UncleKryon
  class Hacker
    DIRNAME = 'yaml'
    KRYON_FILENAME = 'kryon.yaml'
    
    attr_accessor :dirname
    attr_accessor :kryon_filename
    attr_accessor :no_clobber
    attr_accessor :overwrite
    attr_accessor :replace
    
    def initialize(no_clobber=false,replace=true,overwrite=false)
      @dirname = DIRNAME
      @kryon_filename = KRYON_FILENAME
      @no_clobber = no_clobber
      @overwrite = overwrite
      @replace = replace
    end
    
    def parse_kryon_aum_year(year)
      artist = ArtistData.new
      year_parser = KryonAumYearParser.new
      release = year_parser.parse_site(artist,year,get_kryon_year_url(year))
      
      if @no_clobber
        puts release.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=true,who=:kryon_aum_year,overwrite=@overwrite)
      end
    end
    
    def parse_kryon_aum_year_album(date,year=nil)
      begin
        new_date = Date.strptime(date,'%Y.%m.%d')
      rescue ArgumentError
        new_date = Date.strptime(date,'%m.%d')
      end
      
      date = new_date
      
      if !year.nil?
        date = Date.new(year.to_i,date.month,date.day)
      end
      
      year = date.year.to_s
      
      # Try the yaml file
      artist = Util::load_artist_yaml(get_kryon_filepath())
      release = artist.releases[year]
      
      if release.nil?
        # Try manually from the site
        artist = ArtistData.new
        year_parser = KryonAumYearParser.new
        release = year_parser.parse_site(artist,year,get_kryon_year_url(year))
      end
      
      # Find the album
      album = nil
      
      artist.albums.values.each do |a|
        r_year_begin = Util::parse_date(a.r_year_begin)
        r_year_end = Util::parse_date(a.r_year_end)
        date_begin = Util::parse_date(a.date_begin)
        date_end = Util::parse_date(a.date_end)
        
        if (r_year_begin && ((r_year_end  && date >= r_year_begin && date <= r_year_end) ||
                             (!r_year_end && date == r_year_begin))) ||
           (date_begin && ((date_end  && date >= date_begin && date <= date_end) ||
                           (!date_end && date == date_begin)))
          album = a
          break
        end
      end
      
      if album.nil?
        raise "Invalid album[#{date}]"
      end
      
      album_parser = KryonAumYearAlbumParser.new
      album = album_parser.parse_site(artist,album.url)
      
      if @no_clobber
        puts album.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=true,who=:kryon_aum_year_album,overwrite=@overwrite)
      end
    end
    
    def parse_kryon_aum_year_albums(year)
      # Try the yaml file
      artist = Util::load_artist_yaml(get_kryon_filepath())
      release = artist.releases[year]
      
      if release.nil?
        # Try manually from the site
        artist = ArtistData.new
        year_parser = KryonAumYearParser.new
        release = year_parser.parse_site(artist,year,get_kryon_year_url(year))
      end
      
      album_parser = KryonAumYearAlbumParser.new
      
      release.album_ids.each do |album_id|
        album = artist.albums[album_id]
        Log.instance.log.info("Hacking album[#{album.r_year_begin},#{album.r_year_end},#{album.r_topic}]")
        album = album_parser.parse_site(artist,album.url)
      end
      
      if @no_clobber
        puts release.to_s(artist)
      else
        Util::save_artist_yaml(artist,get_kryon_filepath(),replace=true,who=:kryon_aum_year_album,overwrite=@overwrite)
      end
    end
    
    def get_kryon_filepath()
      return File.join(@dirname,@kryon_filename)
    end
    
    def get_kryon_year_url(year)
      if year == '2002-2005'
        url = 'http://www.kryon.com/freeAudio_folder/2002_05_freeAudio.html'
      else
        url = "http://www.kryon.com/freeAudio_folder/#{year}_freeAudio.html"
      end
      
      return url
    end
  end
end

if $0 == __FILE__
  hax = UncleKryon::Hacker.new
  #hax.parse_kryon_aum_year('2017')
  #hax.parse_kryon_aum_year_albums('2017')
end
