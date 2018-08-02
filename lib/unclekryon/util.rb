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

require 'date'
require 'fileutils'
require 'uri'

require 'net/http'

require 'unclekryon/dev_opts'
require 'unclekryon/log'

module UncleKryon
  module Util
    DATE_FORMAT = '%F'
    DATETIME_FORMAT = '%F %T'
    
    def self.add_trail_slash(url)
      url = url + '/' if url !~ /\/\z/
      return url
    end
    
    def self.clean_charset(str)
      return str.encode('utf-8','MacRoman',universal_newline: true) # X-MAC-ROMAN
    end
    
    def self.clean_data(str)
      # Have to use "[[:space:]]" for "&nbsp;" and "<br/>"
      # This is necessary for "<br />\s+" (see 2015 "KRYON IN LIMA, PERU (2)")
      str = str.clone()
      str = clean_charset(str)
      str.gsub!(/[[:space:]]+/,' ') # Replace all spaces with one space
      str.strip!()
      return str
    end
    
    def self.clean_link(url,link)
      if url !~ /\/\z/
        # Don't know if the end is a filename or a dirname, so just assume it is a filename and chop it off
        url = File.dirname(url)
        url = add_trail_slash(url)
      end
      
      # 1st, handle "/" (because you won't have "/../filename", which is invalid)
      slash_regex = /\A(\/+\.*\/*)+/
      
      if link =~ slash_regex
        link = link.gsub(slash_regex,'')
        link = get_top_link(url) + link # get_top_link(...) adds a slash
        
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
      dot_regex = /\A(\.\/+)+/
      
      if link =~ dot_regex
        link = link.gsub(dot_regex,'')
        link = url + link # Slash already added at top of method
        
        return link
      end
      
      # 4th, handle no path
      if link !~ /#{get_top_link(url)}/i
        link = url + link
      end
      
      return link
    end
    
    def self.empty_s?(str)
      return str.nil?() || str.strip().empty?()
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
      return date.nil?() ? nil : date.strftime(DATE_FORMAT)
    end
    
    def self.format_datetime(datetime)
      return datetime.nil?() ? nil : datetime.strftime(DATETIME_FORMAT)
    end
    
    def self.get_top_link(url)
      raise "No top link: #{url}" if DevOpts.instance.dev?() && url !~ /\Ahttps?\:/i
      
      http_regex = /\Ahttps?\:|\A\./i # Check '.' to prevent infinite loop
      
      while File.basename(File.dirname(url)) !~ http_regex
        url = File.dirname(url).strip()
        
        break if url == '.' || url.empty?()
      end
      
      return add_trail_slash(url)
    end
    
    def self.get_url_header_data(url)
      uri = URI(url)
      r = {}
      
      Net::HTTP.start(uri.host,uri.port) do |http|
        resp = http.request_head(uri)
        r = resp.to_hash()
      end
      
      return r
    end
    
    def self.hash_def(hash,keys,value)
      v = hash
      
      for i in 0..keys.length-2
        v = v[keys[i]]
      end
      
      v[keys[keys.length-1]] = value if v[keys[keys.length-1]].nil?()
      return v[keys[keys.length-1]]
    end
    
    def self.hash_def_all(hash,keys,value)
      v = hash
      
      for i in 0..keys.length-2
        if v[keys[i]].nil?()
          v[keys[i]] = {}
          v = v[keys[i]]
        end
      end
      
      v[keys[keys.length-1]] = value if v[keys[keys.length-1]].nil?()
      return v[keys[keys.length-1]]
    end
    
    def self.mk_dirs_from_filepath(filepath)
      dirname = File.dirname(filepath)
      
      if !dirname.nil?()
        raise "Spaces around dirname: '#{dirname}'" if dirname != dirname.strip()
        
        if !Dir.exist?(dirname)
          Log.instance.info("Making dirs: '#{dirname}'...")
          FileUtils.mkdir_p(dirname)
        end
      end
    end
    
    def self.parse_date_s(str)
      return self.empty_s?(str) ? nil : Date.strptime(str,DATE_FORMAT)
    end
    
    def self.parse_datetime_s(str)
      return self.empty_s?(str) ? nil : DateTime.strptime(str,DATETIME_FORMAT)
    end
    
    def self.parse_url_filename(url)
      uri = URI.parse(url)
      r = File.basename(uri.path)
      r = URI.unescape(r)
      return r.strip()
    end
    
    def self.safe_max(a,b)
      return a.nil?() ? b : (b.nil?() ? a : ((a > b) ? a : b))
    end
  end
end
