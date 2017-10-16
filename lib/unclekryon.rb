#!/usr/bin/env ruby

require 'bundler/setup'

require 'optparse'

require 'unclekryon/hacker'
require 'unclekryon/log'
require 'unclekryon/server'
require 'unclekryon/version'

# TODO: make command-line program for hacker, server, uploader
#
# unclekryon hax --dir ./yaml kryon --file 'kryon.yaml' aum year --title 2017 --album 4.30
# unclekryon hax kryon aum year --title 2017 --albums
# unclekryon --no-clobber hax kryon aum year --title 2017
#
# unclekryon srv (uses site dir and current year) (default is just help)
# unclekryon srv --every 10min
# unclekryon srv --once
#
# unclekryon up kryon (upload kryon.yaml to database)

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
        op.banner = <<~EOF
        
          Usage:    unclekryon [options] <commands> [options]
          
          Commands: hax [options] kryon [options] aum year [options]
          
          Options:
        EOF
        
        op.on('-n','--no-clobber','No clobbering of files, dry run') do
          @options[:no_clobber] = true
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      if args_shift()
        parse_hax_cmd()
      end
      
      if !@did_cmd
        @parsers.each do |p|
          puts p
          puts
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
        
        op.on('-a','--album <album>','Album to hack (e.g., 2017.12.25)') do |album|
          @options[:album] = album
        end
        
        op.on('-s','--albums','Hack all albums') do
          @options[:albums] = true
        end
      end
      
      @parsers.push(parser)
      parser.order!(@args)
      
      Log.instance.log.info("Using options[#{@options}]")
      
      hax = Hacker.new(@options[:no_clobber])
      
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
end

if $0 == __FILE__
  main = UncleKryon::Main.new(ARGV)
  main.main
end
