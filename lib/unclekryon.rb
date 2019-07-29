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


require 'rubygems'
require 'bundler/setup'

require 'optparse'

require 'unclekryon/dev_opts'
require 'unclekryon/hacker'
require 'unclekryon/iso'
require 'unclekryon/log'
require 'unclekryon/server'
require 'unclekryon/trainer'
require 'unclekryon/uploader'
require 'unclekryon/util'
require 'unclekryon/version'

require 'unclekryon/data/album_data'
require 'unclekryon/data/artist_data'
require 'unclekryon/data/artist_data_data'
require 'unclekryon/data/aum_data'
require 'unclekryon/data/base_data'
require 'unclekryon/data/pic_data'
require 'unclekryon/data/release_data'
require 'unclekryon/data/social_data'
require 'unclekryon/data/timespan_data'

require 'unclekryon/iso/base_iso'
require 'unclekryon/iso/can_prov_terr'
require 'unclekryon/iso/country'
require 'unclekryon/iso/language'
require 'unclekryon/iso/region'
require 'unclekryon/iso/subregion'
require 'unclekryon/iso/usa_state'

require 'unclekryon/parsers/kryon_aum_year_album_parser'
require 'unclekryon/parsers/kryon_aum_year_parser'

module UncleKryon
  class Main
    OPT_HELP_UPDATED_ON = %Q^Change all "updated_*on" datetimes to <datetime> (e.g., #{Util.format_datetime(DateTime.now())})^
    
    include Logging
    
    def initialize(args)
      @args = args
      @cmd = nil
      @did_cmd = false
      @options = {}
      @parsers = []
    end
    
    def run()
      parser = OptionParser.new do |op|
        op.program_name = 'unclekryon'
        op.version = VERSION
        
        op.banner = <<~EOS
          Usage:    #{op.program_name} [options] <sub_cmd> [options] <sub_cmd>...
          
          Sub Commands:
              hax kryon aum year
              iso list
          
          Options:
        EOS
        
        op.on('-d','--dev','Raise errors on missing data, etc.') do
          DevOpts.instance.dev = true
        end
        op.on('-n','--no-clobber','No clobbering of files, dry run; prints to console') do
          @options[:no_clobber] = true
        end
        op.on('-h','--help','Print help to console')
        op.on('-t','--test','Fill in training data with random values, etc. for fast testing') do
          DevOpts.instance.test = true
        end
        op.on('-v','--version','Print version to console')
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if shift_args()
        parse_hax_cmd()
        parse_iso_cmd()
      end
      
      if !@did_cmd
        if @options[:version]
          puts "#{parser.program_name} v#{parser.version}"
        else
          @parsers.each do |p|
            puts p
            puts
          end
          
          s = <<~EOS
            Examples:
            |    # To view all of the options for the sub commands:
            |    $ #{parser.program_name} hax kryon aum year
            |    $ #{parser.program_name} iso list
            |    
            |    <hax>:
            |    # Train the data 1st before haxing (if there is no training data)
            |    $ #{parser.program_name} -d hax -t kryon aum year -t 2017 -s
            |    $ #{parser.program_name} -d hax -t kryon aum year -t 2017 -a 2.2
            |    
            |    # Hax the data (even though --title is not required, it is recommended)
            |    $ #{parser.program_name} -d hax kryon aum year -t 2017 -s
            |    $ #{parser.program_name} -d hax kryon aum year -t 2017 -a 10.9
            |    $ #{parser.program_name} -d hax kryon aum year -a 2017.9.29
            |    
            |    # Hax the 2nd "6.4" album (if there are 2)
            |    $ #{parser.program_name} -d hax kryon aum year -t 2017 -a 6.4:2
            |    
            |    <iso>:
            |    $ #{parser.program_name} -n iso -u '2019-04-16 11:11:00'
            |    $ #{parser.program_name} iso list -r
          EOS
          puts s.gsub(/^\|/,'')
        end
      end
    end
    
    def shift_args()
      return !@args.nil?() && !(@cmd = @args.shift()).nil?()
    end
    
    def parse_hax_cmd()
      return if !cmd?('hax')
      
      parser = OptionParser.new do |op|
        op.banner = '<hax> options:'

        op.on('-d','--dir <dir>',"Directory to save the hax data to (default: #{Hacker::HAX_DIRNAME})") do |dir|
          @options[:hax_dirname] = dir
        end
        op.on('-t','--train','Train the data using machine learning')
        op.on('-i','--train-dir <dir>',"Directory to save the training data to (default: #{Hacker::TRAIN_DIRNAME})") do |dir|
          @options[:train_dirname] = dir
        end
        op.on('-u','--updated-on <datetime>',OPT_HELP_UPDATED_ON) do |datetime|
          @options[:updated_on] = datetime
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if do_cmd?()
        if @options[:updated_on]
          hax_dirname = @options[:hax_dirname] ? @options[:hax_dirname] : Hacker::HAX_DIRNAME
          gsub_updated_on(hax_dirname,@options[:updated_on])
          
          @did_cmd = true
        end
      end
      
      if shift_args()
        parse_hax_kryon_cmd()
      end
    end
    
    def parse_hax_kryon_cmd()
      return if !cmd?('kryon')
      
      parser = OptionParser.new do |op|
        op.banner = '<kryon> options:'
        
        op.on('-f','--file <file>',"File to save the hax data to (default: #{Hacker::HAX_KRYON_FILENAME})") do |file|
          @options[:hax_kryon_filename] = file
        end
        op.on('-t','--train-file <file>',"File to save the training data to (default: #{Hacker::TRAIN_KRYON_FILENAME})") do |file|
          @options[:train_kryon_filename] = file
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if shift_args()
        parse_hax_kryon_aum_cmd()
      end
    end
    
    def parse_hax_kryon_aum_cmd()
      return if !cmd?('aum')
      
      if shift_args()
        parse_hax_kryon_aum_year_cmd()
      end
    end
    
    def parse_hax_kryon_aum_year_cmd()
      return if !cmd?('year')
      
      parser = OptionParser.new do |op|
        op.banner = '<year> options:'
        
        op.on('-t','--title <title>','Title of year release to hack (e.g., 2017)')
        op.on('-a','--album <album>','Album to hack (e.g., 2017.12.25, 1.10, 6.4:2)')
        op.on('-s','--albums','Hack all albums')
        op.on('-b','--begin-album <album>','Hack all albums starting from <album>') do |begin_album|
          @options[:albums] = true
          @options[:begin_album] = begin_album
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if do_cmd?()
        log_opts()
        
        hacker = Hacker.new(@options)
        
        if @options[:train]
          if @options[:album]
            hacker.train_kryon_aum_year_album(@options[:album],@options[:title])
            @did_cmd = true
          elsif @options[:title]
            if @options[:albums]
              hacker.train_kryon_aum_year_albums(@options[:title],@options[:begin_album])
            else
              hacker.train_kryon_aum_year(@options[:title])
            end
            
            @did_cmd = true
          end
        else
          if @options[:album]
            hacker.parse_kryon_aum_year_album(@options[:album],@options[:title])
            @did_cmd = true
          elsif @options[:title]
            if @options[:albums]
              hacker.parse_kryon_aum_year_albums(@options[:title],@options[:begin_album])
            else
              hacker.parse_kryon_aum_year(@options[:title])
            end
            
            @did_cmd = true
          end
        end
      end
    end
    
    def parse_iso_cmd()
      return if !cmd?('iso')
      
      parser = OptionParser.new do |op|
        op.banner = '<iso> options:'
        
        op.on('-d','--dir <dir>',"Directory to read/write ISO data (default: #{BaseIsos::DEFAULT_DIR})") do |dir|
          @options[:iso_dirname] = dir
        end
        op.on('-u','--updated-on <datetime>',OPT_HELP_UPDATED_ON) do |datetime|
          @options[:updated_on] = datetime
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if do_cmd?()
        if @options[:updated_on]
          iso_dirname = @options[:iso_dirname] ? @options[:iso_dirname] : BaseIsos::DEFAULT_DIR
          gsub_updated_on(iso_dirname,@options[:updated_on])
          
          @did_cmd = true
        end
      end
      
      if shift_args()
        parse_iso_list_cmd()
      end
    end
    
    def parse_iso_list_cmd()
      return if !cmd?('list')
      
      parser = OptionParser.new do |op|
        op.banner = '<list> options:'
        
        op.on('-c','--canada','List Canadian provinces and territories')
        op.on('-u','--usa','List USA states')
        op.on('-o','--country','List countries')
        op.on('-l','--language','List languages')
        op.on('-r','--region','List regions (i.e., continents, etc.)')
        op.on('-s','--subregion','List subregions')
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if do_cmd?()
        if @options[:canada]
          puts Iso.can_provs_terrs
          @did_cmd = true
        elsif @options[:usa]
          puts Iso.usa_states
          @did_cmd = true
        elsif @options[:country]
          puts Iso.countries
          @did_cmd = true
        elsif @options[:language]
          puts Iso.languages
          @did_cmd = true
        elsif @options[:region]
          puts Iso.regions
          @did_cmd = true
        elsif @options[:subregion]
          puts Iso.subregions
          @did_cmd = true
        end
      end
    end
    
    def gsub_updated_on(dirname,updated_on)
      updated_on = Util.parse_datetime_s(updated_on) # Raise errors on bad format
      updated_on = Util.format_datetime(updated_on)
      
      Dir.glob(File.join(dirname,'*.yaml')) do |filepath|
        lines = IO.readlines(filepath)
        update_count = 0
        
        lines.each_with_index do |line,i|
          if line =~ /\A\s*updated\_.*on\:.*\Z/i
            line = line.split(':')[0] << ": '#{updated_on}'"
            lines[i] = line
            update_count += 1
          end
        end
        
        if !@options[:no_clobber]
          File.open(filepath,'w') do |file|
            file.puts lines
          end
        end
        
        puts %Q^"#{filepath}" updated_on: #{update_count}^
      end
    end
    
    def log_opts()
      log.info("Using options#{@options}")
    end
    
    def cmd?(cmd)
      return !@did_cmd && !@cmd.nil?() && @cmd.match?(/\A[[:space:]]*#{Regexp.escape(cmd)}[[:space:]]*\z/i)
    end
    
    def do_cmd?()
      return !@options[:help] && !@options[:version]
    end
  end
end

if $0 == __FILE__
  main = UncleKryon::Main.new(ARGV)
  main.run()
end
