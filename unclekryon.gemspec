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


lib = File.expand_path('../lib',__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'unclekryon/version'

Gem::Specification.new() do |spec|
  spec.name        = 'unclekryon'
  spec.version     = UncleKryon::VERSION
  spec.authors     = ['Jonathan Bradley Whited (@esotericpig)']
  spec.email       = ['bradley@esotericpig.com']
  spec.licenses    = ['GPL-3.0-or-later']
  spec.homepage    = 'https://github.com/esotericpig/UncleKryon-server'
  spec.summary     = 'UncleKryon server (& hacker).'
  spec.description = 'UncleKryon server (& hacker) for the UncleKryon mobile apps.'
  
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/esotericpig/UncleKryon-server/issues',
    'homepage_uri'    => 'https://github.com/esotericpig/UncleKryon-server',
    'source_code_uri' => 'https://github.com/esotericpig/UncleKryon-server'
  }
  
  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]
  
  spec.files = Dir.glob(File.join("{#{spec.require_paths.join(',')}}",'**','*.{rb}')) +
               Dir.glob(File.join(spec.bindir,'**',"{#{spec.executables.join(',')}}")) +
               Dir.glob(File.join("{hax,iso,test,train}",'**','*.{rb,yaml}')) +
               %W( Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile ) +
               %w( LICENSE README.md )
  
  spec.post_install_message = "You can now use [#{spec.executables.join(', ')}] on the command line."
  
  spec.required_ruby_version = '>= 2.4.0'
  spec.requirements << 'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html'
  
  spec.add_runtime_dependency 'nbayes'  ,'~> 0.1.2' # For training type of text (machine learning)
  spec.add_runtime_dependency 'nokogiri','~> 1.10'  # For hacking HTML
  
  spec.add_development_dependency 'bundler' ,'~> 1.17'
  spec.add_development_dependency 'irb'     ,'~> 1.0'
  spec.add_development_dependency 'minitest','~> 5.11' # For testing
  spec.add_development_dependency 'rake'    ,'~> 12.3'
  spec.add_development_dependency 'raketeer','~> 0.1'  # For Nokogiri & IRB rake tasks
end
