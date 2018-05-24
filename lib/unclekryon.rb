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
          Usage:    #{op.program_name} [options] <command> [options] <command>...
          
          Commands:
              hax kryon aum year
          
          Options:
        EOS
        
        op.on('-n','--no-clobber','No clobbering of files, dry run; prints to console') do
          @options[:no_clobber] = true
        end
        op.on('-h','--help','Print help to console')
        op.on('-v','--version','Print version to console')
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      if shift_args()
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
            |    # Train the data 1st before haxing (if there is no training data)
            |    $ #{parser.program_name} hax -t kryon aum year -t 2017
            |    $ #{parser.program_name} hax -t kryon aum year -t 2017 -a 2.2
            |    
            |    # Hax the data (even though --title is not required, it is recommended)
            |    $ #{parser.program_name} -n hax kryon aum year -t 2017
            |    $ #{parser.program_name} hax -d ./db -o kryon -f k.yaml aum year -t 2017
            |    $ #{parser.program_name} hax -r kryon aum year -t 2017 -s
            |    $ #{parser.program_name} hax -r kryon aum year -a 2017.9.29
            |    $ #{parser.program_name} hax -r kryon aum year -t 2017 -a 10.9
            |    
            |    # Hax the 2nd "6.4" album (if there are 2)
            |    $ #{parser.program_name} hax -r kryon aum year -t 2017 -a 6.4:2
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
        op.on('-f','--fast','Hax it fast at the expense of losing data, ONLY for debugging') do
          @options[:slow] = false
        end
        op.on('-r','--replace',"Replace the new hax data loaded, but don't overwrite non-loaded data")
        op.on('-o','--overwrite','Overwrite all hax data, even non-loaded data; overrides --replace')
        op.on('-t','--train','Train the data using machine learning')
        op.on('-i','--train-dir <dir>',"Directory to save the training data to (default: #{Hacker::TRAIN_DIRNAME})") do |dir|
          @options[:train_dirname] = dir
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
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
      end
      
      @parsers.push(parser)
      parser.order!(@args,into: @options)
      
      return if !do_cmd?()
      
      log_opts()
      
      hacker = Hacker.new(@options)
      
      if @options[:train]
        if @options[:album]
          hacker.train_kryon_aum_year_album(@options[:album],@options[:title])
          @did_cmd = true
        elsif @options[:title]
          hacker.train_kryon_aum_year(@options[:title])
          @did_cmd = true
        end
      else
        if @options[:album]
          hacker.parse_kryon_aum_year_album(@options[:album],@options[:title])
          @did_cmd = true
        elsif @options[:title]
          if @options[:albums]
            hacker.parse_kryon_aum_year_albums(@options[:title])
          else
            hacker.parse_kryon_aum_year(@options[:title])
          end
          
          @did_cmd = true
        end
      end
    end
    
    def log_opts()
      log.info("Using options#{@options}")
    end
    
    def cmd?(cmd)
      return !@did_cmd && @cmd.match?(/\A[[:space:]]*#{Regexp.escape(cmd)}[[:space:]]*\z/i)
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
