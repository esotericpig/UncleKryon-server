# encoding: UTF-8
# frozen_string_literal: true

#--
# This file is part of UncleKryon-server.
# Copyright (c) 2017-2020 Jonathan Bradley Whited (@esotericpig)
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
require 'raketeer/irb'
require 'raketeer/nokogiri_installs'
require 'raketeer/run'

require 'unclekryon/version'

PKG_DIR = 'pkg'

CLEAN.exclude('{.git,stock}/**/*')
CLOBBER.include('doc/',File.join(PKG_DIR,''))

task default: [:irb]

desc "Package data as a Zip file into '#{File.join(PKG_DIR,'')}'"
task :pkg_data do
  pattern = File.join('{hax,train}','**','*.{yaml,yml}')
  zip_name = "unclekryon-data-#{UncleKryon::VERSION}.zip"
  
  zip_file = File.join(PKG_DIR,zip_name)
  
  mkdir_p PKG_DIR
  
  sh 'zip','-9rv',zip_file,*Dir.glob(pattern).sort()
end

Rake::TestTask.new() do |task|
  task.libs = ['lib','test']
  task.pattern = File.join('test','**','*_test.rb')
  task.description += " ('#{task.pattern}')"
  task.verbose = false
  task.warning = true
end
