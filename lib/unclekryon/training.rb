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

require 'nbayes'

require 'unclekryon/util'

module UncleKryon
  module Training
    attr_accessor :max_train_tag
    attr_accessor :max_train_tag_id
    attr_writer :train
    attr_accessor :train_filepath
    attr_accessor :train_tags
    attr_accessor :trainer
    
    def init_train()
      if @train_filepath.nil?() || (@train_filepath = @train_filepath.strip()).empty?()
        raise ArgumentError,'Training filepath cannot be empty'
      end
      
      @trainer = File.exist?(@train_filepath) ? NBayes::Base.from(@train_filepath) : NBayes::Base.new()
      
      @max_train_tag = 0
      @max_train_tag_id = 0
      
      @train_tags.each do |id,tag|
        @max_train_tag = tag.length if tag.length > @max_train_tag
        @max_train_tag_id = id.length if id.length > @max_train_tag_id
      end
      
      @max_train_tag = -@max_train_tag # Left justify
      @max_train_tag_id += 2 # Indention
      
      return self
    end
    
    def save_trainer()
      Util.mk_dirs_from_filepath(@train_filepath)
      @trainer.dump(@train_filepath)
    end
    
    def train(text,tokens)
      puts '#################'
      puts '# Training Tags #'
      puts '#################'
      
      tf = '%%%is = %%%is' % [@max_train_tag_id,@max_train_tag]
      
      @train_tags.each do |id,tag|
        puts tf % [id,tag]
      end
      
      puts '-----------------'
      puts text
      puts '-----------------'
      print 'What is it? '
      
      tag_id = STDIN.gets.chomp().strip() # STDIN because app accepts args
      #puts (tag_id = @train_tags.keys.sample()) # For testing purposes
      puts
      
      raise "Invalid tag ID[#{tag_id}]" if !@train_tags.include?(tag_id)
      tag = @train_tags[tag_id]
      
      @trainer.train(tokens,tag)
    end
    
    def trainer_tag(tokens)
      return @trainer.classify(tokens).max_class
    end
    
    def train?()
      return @train
    end
    
    def trainer_s()
      s = ''
      
      s << @trainer.to_yaml()
      s << "\n"
      s << @trainer.data.category_stats()
      
      return s
    end
  end
end
