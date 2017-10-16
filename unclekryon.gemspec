# encoding: utf-8
# frozen_string_literal: true

# TODO: include license text here

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
  
  spec.files                  = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.md)
  spec.require_paths          = ['lib']
  spec.bindir                 = 'bin'
  spec.executables            = ['unclekryon']
  spec.post_install_message   = 'You can now use "unclekryon" on the command-line.'
  
  spec.required_ruby_version  = '>= 2.3.0' # 2.1.0 for nokogiri; 2.3.0 for indention heredoc "<<~"
  spec.requirements          << 'Fedora:   yum install -y gcc ruby-devel zlib-devel'
  spec.requirements          << 'nokogiri: http://www.nokogiri.org/tutorials/installing_nokogiri.html'
  
  spec.add_runtime_dependency 'nokogiri','>= 1.8.1' # For hacking html
  
  spec.add_development_dependency 'bundler','>= 1.15'
  #spec.add_development_dependency 'rake','>= 10.0'
end
