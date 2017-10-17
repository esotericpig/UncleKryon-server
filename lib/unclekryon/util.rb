#!/usr/bin/env ruby

require 'date'
require 'digest'
require 'uri'
require 'yaml'

require 'net/http'

require 'unclekryon/log'

module UncleKryon
  module Util
    DATE_FORMAT = '%F'
    
    def self.add_trail_slash(url)
      url = url + '/' if url !~ /\/\z/
      return url
    end
    
    def self.clean_data(str)
      # Have to use [[:space:]] for &nbsp; and <br/>
      
      #str = str.gsub(/\u00a0/,' ') # Try to replace &nbsp; with normal spaces
      #str = str.gsub(/\A[[:space:]]+/,'') # lstrip
      #str = str.gsub(/[[:space:]]+\z/,'') # rstrip
      
      # This is necessary for "<br />\s+" (see 2015 "KRYON IN LIMA, PERU (2)")
      str = str.gsub(/[[:space:]]+/,' ') # Replace all spaces with one space
      str = str.strip
      
      return str
    end
    
    def self.clean_link(url,link)
      if url !~ /\/\z/ # / \z
        # Don't know if the end is a filename or a dirname, so just assume it is a filename and chop it off
        url = File.dirname(url)
        url = add_trail_slash(url)
      end
      
      # 1st, handle "/" (because you won't have "/../filename", which is invalid)
      slash_regex = /\A(\/+\.*\/*)+/ # \A (/+ .* /*)+
      
      if link =~ slash_regex
        link = ling.gsub(slash_regex,'')
        link = get_top_link(url) + link # #get_top_link(...) adds a slash
        
        return link # Already handles "../" or "./" in the regex
      end
      
      # 2nd, handle "../" (and potentially "../././/" or "..//")
      # - Ignores "./" if has it
      dotdot_regex = /\A(\.\.\/)((\.\/)*(\/)*)*/ # \A (../) ( (./)* (/)* )*
      num_dirs = 0 # Could be a boolean; left as int because of legacy code
      
      while link =~ dotdot_regex
        num_dirs = num_dirs + 1
        link = link.gsub(dotdot_regex,'')
        url = File.dirname(url)
      end
      
      if num_dirs > 0
        link = add_trail_slash(url) + link
        
        return link # Already handled "./" in the regex
      end
      
      # 3rd, handle "./"
      dot_regex = /\A(\.\/+)+/ # \A ( . /+ )+
      
      if link =~ dot_regex
        link = link.gsub(dot_regex,'')
        link = url + link # Slash already added at top of method
        
        return link
      end
      
      # 4th, handle no path
      if link !~ /#{url}/i
        link = url + link
      end
      
      return link
    end
    
    def self.fix_shortwith_text(text)
      if text =~ /w\/[[:alnum:]]/i
        # I think it looks better with a space, personally.
        #  Some grammar guides say no space, but the Chicago style guide says there should be a space when it
        #    is a word by itself.
        text = text.gsub(/w\//i,'w/ ')
      end
      
      return text
    end
    
    def self.format_date(date)
      return date.strftime(DATE_FORMAT)
    end
    
    def self.gen_id(url)
      # base64 is shorter than hex
      return Digest::MD5.base64digest(url)
    end
    
    def self.get_top_link(url)
      http_regex = /\A(http\:)|(\.)/i # Check '.' to prevent infinite loop
      prev_link = url
      
      i = 100 # Prevent infinite loop (maybe raise an exception instead?)
      
      while (next_link = File.dirname(prev_link)) !~ http_regex &&
          (i = i - 1) >= 0
        prev_link = next_link
      end
      
      return add_trail_slash(prev_link)
    end
    
    def self.get_url_content_data(url)
      uri = URI(url)
      r = {}
      
      Net::HTTP.start(uri.host,uri.port) do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)
        r['length'] = response['content-length']
      end
      
      return r
    end
    
    def self.hash_def(hash,keys,value)
      v = hash
      
      for i in 0..keys.length-2
        v = v[keys[i]]
      end
      
      v[keys[keys.length-1]] = value if v[keys[keys.length-1]].nil?
      return v[keys[keys.length-1]]
    end
    
    def self.hash_def_all(hash,keys,value)
      v = hash
      
      for i in 0..keys.length-2
        if v[keys[i]].nil?
          v[keys[i]] = {}
          v = v[keys[i]]
        end
      end
      
      v[keys[keys.length-1]] = value if v[keys[keys.length-1]].nil?
      return v[keys[keys.length-1]]
    end
    
    def self.load_artist_yaml(filename)
      filedata = YAML.load_file(filename) if File.exists?(filename)
      filedata = {} if !filedata
      
      artist = ArtistData.new
      
      self.hash_def(filedata,['Artist'],{})
      artist.releases = self.hash_def(filedata,['Artist','Releases'],artist.releases)
      artist.albums = self.hash_def(filedata,['Artist','Albums'],artist.albums)
      artist.aums = self.hash_def(filedata,['Artist','Aums'],artist.aums)
      artist.pics = self.hash_def(filedata,['Artist','Pics'],artist.pics)
      
      return artist
    end
    
    def self.parse_date(date)
      return (date && !date.empty?) ? Date.strptime(date,DATE_FORMAT) : nil
    end
    
    def self.parse_kryon_date(date)
      date.gsub!(/Feburary/i,'February') # "Feburary 2-13, 2017"
      date.gsub!(/SEPT\s+/i,'Sep ') # "SEPT 29 - OCT 9, 2017"
      date.gsub!(/Septembe\s+/i,'September') # "Septembe 4, 2016"
      
      # "May 6 2017"
      comma = date.include?(',') ? ',' : ''
      r = [2]
      
      begin
        if date.include?('-')
          # "SEPT 29 - OCT 9, 2017"
          if date =~ /[[:alpha:]]+\s+[[:digit:]]+\s+\-\s+[[:alpha:]]+\s+[[:digit:]]+/
            r1f = "%B %d - %B %d#{comma} %Y"
          else
            # "MAY 15-16-17, 2017" and "January 7-8, 2017"
            r1f = (date =~ /\-.*\-/) ? "%B %d-%d-%d#{comma} %Y" : "%B %d-%d#{comma} %Y"
          end
          
          r[1] = Date.strptime(date,r1f)
          r[0] = Date.strptime(date,'%B %d')
          r[0] = Date.new(r[1].year,r[0].month,r[0].day)
        elsif date.include?('/')
          # "JULY/AUG 2017"
          r[1] = Date.strptime(date,'%b/%b %Y')
          r[0] = Date.strptime(date,'%b')
          r[0] = Date.new(r[1].year,r[0].month,r[0].day)
        else
          r[0] = Date.strptime(date,"%B %d#{comma} %Y")
          r[1] = nil
        end
      rescue ArgumentError => e
        # TODO: make own methods; pass in e; log e and e.backtrace.join("\n\t> ")
        Log.instance.log.fatal("Invalid Date: '#{date}'")
        raise
      end
      
      r[0] = (!r[0].nil?) ? self.format_date(r[0]) : ''
      r[1] = (!r[1].nil?) ? self.format_date(r[1]) : ''
      
      return r
    end
    
    def self.parse_url_filename(url)
      uri = URI.parse(url)
      return File.basename(uri.path)
    end
    
    def self.save_artist_yaml(artist,filename,replace=false,who=nil,overwrite=false)
      filedata = YAML.load_file(filename) if File.exists?(filename)
      filedata = {} if !filedata
      
      self.hash_def(filedata,['Artist'],{})
      
      if overwrite
        if who.nil?
          filedata['Artist']['Releases'] = artist.releases
          filedata['Artist']['Albums'] = artist.albums
          filedata['Artist']['Aums'] = artist.aums
          filedata['Artist']['Pics'] = artist.pics
        elsif who == :kryon_aum_year
          artist.releases.each do |key,release|
            filedata['Artist']['Releases'][key] = release
          end
          
          artist.albums.each do |key,album|
            if filedata['Artist']['Albums'][key].nil?
              filedata['Artist']['Albums'][key] = album
            else
              filedata['Artist']['Albums'][key].set_release_data(album)
            end
          end
        elsif who == :kryon_aum_year_album
          artist.albums.each do |key,album|
            if filedata['Artist']['Albums'][key].nil?
              filedata['Artist']['Albums'][key] = album
            else
              filedata['Artist']['Albums'][key].set_nonrelease_data(album)
            end
          end
          
          artist.aums.each do |key,aum|
            filedata['Artist']['Aums'][key] = aum
          end
          
          artist.pics.each do |key,pic|
            filedata['Artist']['Pics'][key] = pic
          end
        end
      else
        self.hash_def(filedata,['Artist','Releases'],{})
        self.hash_def(filedata,['Artist','Albums'],{})
        self.hash_def(filedata,['Artist','Aums'],{})
        self.hash_def(filedata,['Artist','Pics'],{})
        
        artist.releases.each do |key,release|
          self.hash_def(filedata,['Artist','Releases',key],release)
        end
        
        artist.albums.each do |key,album|
          if !replace || filedata['Artist']['Albums'][key].nil?
            self.hash_def(filedata,['Artist','Albums',key],album)
          elsif who == :kryon_aum_year
            filedata['Artist']['Albums'][key].set_release_data(album)
          elsif who == :kryon_aum_year_album
            filedata['Artist']['Albums'][key].set_nonrelease_data(album)
          end
        end
        
        artist.aums.each do |key,aum|
          self.hash_def(filedata,['Artist','Aums',key],aum)
        end
        
        artist.pics.each do |key,pic|
          self.hash_def(filedata,['Artist','Pics',key],pic)
        end
      end
      
      File.open(filename,'w') do |f|
        YAML.dump(filedata,f)
      end
    end
  end
end
