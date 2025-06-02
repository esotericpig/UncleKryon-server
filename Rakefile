# encoding: UTF-8
# frozen_string_literal: true

require 'bundler/gem_tasks'

require 'rake/clean'
require 'rake/testtask'
require 'raketeer/irb'
require 'raketeer/nokogiri_installs'
require 'raketeer/run'

require 'unclekryon/version'

PKG_DIR = 'pkg'

CLEAN.exclude('{.git,stock}/**/*')
CLOBBER.include('doc/',"#{PKG_DIR}/")

task default: [:irb]

desc "Package data as a Zip file into '#{PKG_DIR}/'"
task :pkg_data do
  pattern = '{hax,train}/**/*.{yaml,yml}'
  zip_name = "unclekryon-data-#{UncleKryon::VERSION}.zip"

  zip_file = File.join(PKG_DIR,zip_name)

  mkdir_p PKG_DIR

  sh 'zip','-9rv',zip_file,*Dir.glob(pattern)
end

Rake::TestTask.new do |task|
  task.libs = ['lib','test']
  task.pattern = 'test/**/*_test.rb'
  task.description += " ('#{task.pattern}')"
  task.verbose = false
  task.warning = true
end
