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


require 'bundler/gem_tasks'

require 'rake/clean'
require 'rake/testtask'

CLEAN.exclude('.git/','stock/')
CLOBBER.include('doc/')

task :default => [:irb]

desc 'Open an irb session loaded with this library'
task :irb do
  sh_cmd = ['irb']
  
  sh_cmd.push('-r','rubygems')
  sh_cmd.push('-r','bundler/setup')
  sh_cmd.push('-r','unclekryon')
  sh_cmd << '-w'
  
  sh *sh_cmd
end

desc 'Install Nokogiri libs for Ubuntu/Debian'
task :nokogiri_apt do
  sh_cmd = ['sudo','apt-get','install']
  
  sh_cmd << 'build-essential'
  sh_cmd << 'libgmp-dev'
  sh_cmd << 'liblzma-dev'
  sh_cmd << 'patch'
  sh_cmd << 'ruby-dev'
  sh_cmd << 'zlib1g-dev'
  
  sh *sh_cmd
end

desc 'Install Nokogiri libs for Fedora/CentOS/Red Hat'
task :nokogiri_dnf do
  sh_cmd = ['sudo','dnf','install']
  
  sh_cmd << 'gcc'
  sh_cmd << 'ruby-devel'
  sh_cmd << 'zlib-devel'
  
  sh *sh_cmd
end

desc 'Install Nokogiri libs for other OSes'
task :nokogiri_other do
  puts 'https://nokogiri.org/tutorials/installing_nokogiri.html'
end

Rake::TestTask.new() do |task|
  task.libs = ['lib','test']
  task.pattern = File.join('test','**','*_test.rb')
  task.description += " ('#{task.pattern}')"
  task.verbose = true
  task.warning = true
end
