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

require 'bundler/setup'

require 'optparse'

require 'unclekryon/hacker'
require 'unclekryon/log'
require 'unclekryon/server'
require 'unclekryon/version'

# TODO: make command-line program for hacker, server, uploader
#
# hax kryon scroll main, hax lems aum main, hax ssb scroll year
#
# unclekryon srv (uses site dir and current year) (default is just help)
# unclekryon srv --every 10min
# unclekryon srv --once
#
# unclekryon up --dir x --file x kryon/lems/ssb (upload kryon.yaml to database)
#
# for bash completion, have "--bash-completion" option output bash completion options and use in file

module UncleKryon
  class Main
    def initialize(args)
      @args = args
      @cmd = nil
      @did_cmd = false
      @options = {}
      @parsers = []
    end
    
    def args_shift
      return !@args.nil? && !(@cmd = @args.shift).nil?
    end
    
    def main
      parser = OptionParser.new do |op|
        op.program_name = 'unclekryon'
        op.version = VERSION
        
        op.banner = <<~EOS
          Usage:    #{op.program_name} [options] <commands> [options]
          
          Commands: [options] hax [options] kryon [options] aum year [options]
          
          Options:
        EOS
        
        op.on('-n','--no-clobber','No clobbering of files, dry run; prints to console') do
          @options[:no_clobber] = true
        end
        
        op.on('-h','--help','Print help to console') do
          @options[:help] = true
        end
        
        op.on('-v','--version','Print version to console') do
          @options[:help] = true # Don't do cmd
          @options[:version] = true
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      if args_shift()
        parse_hax_cmd()
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
            |    <hax>:
            |    $ #{parser.program_name} -n hax kryon aum year -t 2017
            |    $ #{parser.program_name} hax -d ./db -o kryon -f k.yaml aum year -t 2017
            |    $ #{parser.program_name} hax -r kryon aum year -t 2017 -s
            |    $ #{parser.program_name} hax -r kryon aum year -a 2017.9.29
            |    $ #{parser.program_name} hax -r kryon aum year -t 2017 -a 10.9
          EOS
          puts s.gsub(/\|(\s\s\s\s+)/,'\1')
        end
      end
    end
    
    def parse_hax_cmd
      return if @cmd !~ /\Ahax\z/i
      
      parser = OptionParser.new do |op|
        op.banner = '<hax> options:'

        op.on('-d','--dir <dir>',"Directory to save the yaml data to (default: #{Hacker::DIRNAME})") do |dir|
          @options[:dir] = dir
        end
        
        op.on('-r','--replace',"Replace the new data loaded, but don't overwrite non-loaded data") do
          @options[:replace] = true
        end
        
        op.on('-o','--overwrite',"Overwrite all data, even non-loaded data; overrides --replace") do
          @options[:overwrite] = true
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      if args_shift()
        parse_hax_kryon_cmd()
      end
    end
    
    def parse_hax_kryon_cmd
      return if @cmd !~ /\Akryon\z/i
      
      parser = OptionParser.new do |op|
        op.banner = '<kryon> options:'
        
        op.on('-f','--file <file>',"File to save the yaml data to (default: #{Hacker::KRYON_FILENAME})") do |file|
          @options[:file] = file
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      if args_shift()
        parse_hax_kryon_aum_cmd()
      end
    end
    
    def parse_hax_kryon_aum_cmd
      return if @cmd !~ /\Aaum\z/i
      
      if args_shift()
        parse_hax_kryon_aum_year_cmd()
      end
    end
    
    def parse_hax_kryon_aum_year_cmd
      return if @cmd !~ /\Ayear\z/i
      
      parser = OptionParser.new do |op|
        op.banner = '<year> options:'
        
        op.on('-t','--title <title>','Title of year release to hack (e.g., 2017)') do |title|
          @options[:title] = title
        end
        
        op.on('-a','--album <album>','Album to hack (e.g., 2017.12.25, 1.10)') do |album|
          @options[:album] = album
        end
        
        op.on('-s','--albums','Hack all albums') do
          @options[:albums] = true
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      Log.instance.log.info("Using options#{@options}")
      
      if !@options[:help]
        hax = Hacker.new(no_clobber=@options[:no_clobber],replace=@options[:replace],overwrite=@options[:overwrite])
        
        if @options[:dir]
          hax.dirname = @options[:dir]
        end
        if @options[:file]
          hax.kryon_filename = @options[:file]
        end
        
        if @options[:album]
          hax.parse_kryon_aum_year_album(@options[:album],@options[:title])
          @did_cmd = true
        elsif @options[:title]
          if @options[:albums]
            hax.parse_kryon_aum_year_albums(@options[:title])
          else
            hax.parse_kryon_aum_year(@options[:title])
          end
          @did_cmd = true
        end
      end
    end
    
    def to_flag(b)
      return b ? 'on' : 'off'
    end
  end
end

if $0 == __FILE__
  main = UncleKryon::Main.new(ARGV)
  main.main
end
