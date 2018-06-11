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

require 'nbayes'

require 'unclekryon/dev_opts'
require 'unclekryon/log'
require 'unclekryon/util'

module UncleKryon
  class Trainer
    attr_accessor :max_tag_id_length
    attr_accessor :max_tag_length
    attr_accessor :tags
    attr_accessor :trainer
    
    def self.to_tokens(text)
      tokens = []
      
      text.split(/[[:space:]]+/).each() do |t|
        t.gsub!(/[[:punct:][:cntrl:]]+/,'')
        tokens.push(t) if !t.empty?()
      end
      
      return tokens
    end
    
    def initialize(tags={})
      @max_tag_id_length = 0
      @max_tag_length = 0
      @tags = tags
      @trainer = NBayes::Base.new()
      
      init_lengths()
    end
    
    def init_lengths()
      @max_tag_id_length = 0
      @max_tag_length = 0
      
      @tags.each do |id,tag|
        @max_tag_id_length = id.length if id.length > @max_tag_id_length
        @max_tag_length = tag.length if tag.length > @max_tag_length
      end
      
      @max_tag_id_length += 2 # Indention
      @max_tag_length = -@max_tag_length # Left justify
    end
    
    def train(text)
      guess_tag = self.tag(text) # Try and guess
      tokens = self.class.to_tokens(text)
      
      puts '#################'
      puts '# Training Tags #'
      puts '#################'
      
      tf = '%%%is = %%%is' % [@max_tag_id_length,@max_tag_length]
      @tags.each do |id,tag|
        puts tf % [id,tag]
      end
      puts "<Enter> = Guess: #{guess_tag}"
      
      puts '-----------------'
      puts text
      puts '-----------------'
      print 'What is it? '
      
      # Use -t/--test option
      if DevOpts.instance.test?()
        puts (tag_id = @tags.keys.sample()) # For testing purposes
      else
        tag_id = STDIN.gets().chomp().strip() # STDIN because app accepts args
      end
      puts
      
      if tag_id.empty?()
        raise "Invalid guess tag[#{guess_tag}]" if !@tags.value?(guess_tag)
        tag = guess_tag
      else
        raise "Invalid tag ID[#{tag_id}]" if !@tags.include?(tag_id)
        tag = @tags[tag_id]
      end
      
      @trainer.train(tokens,tag)
      
      return tag
    end
    
    def tag(text)
      return @trainer.classify(self.class.to_tokens(text)).max_class
    end
    
    def to_s()
      s = ''
      s << @trainer.to_yaml()
      s << "\n"
      s << @trainer.data.category_stats()
      
      return s
    end
  end
  
  class Trainers
    attr_accessor :filepath
    attr_accessor :trainers
    
    def initialize(filepath=nil)
      @filepath = filepath
      @trainers = {}
    end
    
    def load_file()
      if @filepath.nil?() || (@filepath = @filepath.strip()).empty?()
        raise ArgumentError,'Training filepath cannot be empty'
      end
      
      if File.exist?(@filepath)
        y = YAML.load_file(@filepath)
        
        y.each() do |id,trainer|
          if !@trainers.key?(id)
            @trainers[id] = trainer
          else
            @trainers[id].tags = trainer.tags.merge(@trainers[id].tags)
            @trainers[id].trainer = trainer.trainer
          end
          
          @trainers[id].trainer.reset_after_import()
          @trainers[id].init_lengths()
        end
      end
    end
    
    def save_to_file()
      if @filepath.nil?() || (@filepath = @filepath.strip()).empty?()
        raise ArgumentError,'Training filepath cannot be empty'
      end
      
      Util.mk_dirs_from_filepath(@filepath)
      
      File.open(@filepath,'w') do |f|
        f.write(to_s())
      end
    end
    
    def [](id)
      @trainers[id]
    end
    
    def []=(id,trainer)
      @trainers[id] = trainer
    end
    
    def to_s()
      return YAML.dump(@trainers)
    end
  end
end

if $0 == __FILE__
  fp = 'test.yaml'
  ts = UncleKryon::Trainers.new(fp)
  
  ctx = ['dark black bitter',
         'double espresso steamed milk foam',
         'espresso steamed milk']
  ttx = ['no withering and oxidation',
         'broom-like, South Africa',
         'young, minimal']
  
  if File.exist?(fp)
    ts.load_file()
    puts ts
    puts
    
    puts '[Coffee]'
    ctx.each do |v|
      puts "'#{v}' => #{ts['coffee'].tag(v)}"
    end
    puts
    
    puts '[Tea]'
    ttx.each do |v|
      puts "'#{v}' => #{ts['tea'].tag(v)}"
    end
    puts
    
    puts 'What kind of drink would you like?'
    txt = STDIN.gets().chomp().strip()
    puts "coffee => #{ts['coffee'].tag(txt)}"
    puts "tea    => #{ts['tea'].tag(txt)}"
  else
    ts['coffee'] = UncleKryon::Trainer.new(
      {'b'=>'black','c'=>'cappuccino','l'=>'latte'})
    ts['tea'] = UncleKryon::Trainer.new(
      {'g'=>'green','r'=>'red','w'=>'white'})
    
    ctx.each do |v|
      ts['coffee'].train(v)
    end
    ttx.each do |v|
      ts['tea'].train(v)
    end
    
    ts.save_to_file()
  end
end
