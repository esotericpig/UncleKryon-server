# encoding: utf-8
# frozen_string_literal: true

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

lib = File.expand_path('../lib',__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'unclekryon/version'

Gem::Specification.new do |spec|
  spec.name                   = 'unclekryon'
  spec.version                = UncleKryon::VERSION
  spec.authors                = ['Jonathan Bradley Whited @esotericpig']
  spec.email                  = ['']
  spec.license                = 'GPL-3.0'
  
  spec.summary                = 'UncleKryon server (& hacker)'
  spec.description            = 'UncleKryon server (& hacker) for the UncleKryon Android app'
  spec.homepage               = 'https://github.com/esotericpig/UncleKryon-server'
  
  spec.files                  = Dir.glob("{bin,lib}/**/*") + %w(
                                    Gemfile
                                    Gemfile.lock
                                    LICENSE
                                    Rakefile
                                    README.md
                                    unclekryon.gemspec
                                  )
  spec.require_paths          = ['lib']
  spec.bindir                 = 'bin'
  spec.executables            = ['unclekryon']
  spec.post_install_message   = 'You can now use "unclekryon" on the command-line.'
  
  # 2.1.0 for nokogiri
  # 2.3.0 for indention heredoc "<<~"
  spec.required_ruby_version  = '>= 2.3.0'
  spec.requirements          << 'Fedora:   dnf install gcc ruby-devel zlib-devel'
  spec.requirements          << 'nokogiri: http://www.nokogiri.org/tutorials/installing_nokogiri.html'
  
  spec.add_runtime_dependency 'iso-639' ,'>= 0.2.8' # For language codes
  spec.add_runtime_dependency 'nokogiri','>= 1.8.1' # For hacking html
  
  spec.add_development_dependency 'bundler','>= 1.15'
  #spec.add_development_dependency 'rake','>= 10.0'
end
