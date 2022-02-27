# encoding: UTF-8
# frozen_string_literal: true


lib = File.expand_path(File.join('..','lib'),__FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'unclekryon/version'

Gem::Specification.new do |spec|
  spec.name        = 'unclekryon'
  spec.version     = UncleKryon::VERSION
  spec.authors     = ['Jonathan Bradley Whited']
  spec.email       = ['code@esotericpig.com']
  spec.licenses    = ['GPL-3.0-or-later']
  spec.homepage    = 'https://github.com/esotericpig/UncleKryon-server'
  spec.summary     = 'Uncle Kryon server (& hacker).'
  spec.description = 'Uncle Kryon server (& hacker) for the Uncle Kryon mobile apps.'

  spec.metadata = {
    'homepage_uri'    => 'https://github.com/esotericpig/UncleKryon-server',
    'source_code_uri' => 'https://github.com/esotericpig/UncleKryon-server',
    'changelog_uri'   => 'https://github.com/esotericpig/UncleKryon-server/releases',
    'bug_tracker_uri' => 'https://github.com/esotericpig/UncleKryon-server/issues',
  }

  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]

  spec.files = [
    Dir.glob(File.join("{#{spec.require_paths.join(',')},test}",'**','*.{erb,rb}')),
    Dir.glob(File.join(spec.bindir,'*')),
    Dir.glob(File.join('{hax,iso,train}','**','*.{yaml,yml}')),
    %W[ Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile ],
    %w[ LICENSE README.md ],
  ].flatten

  spec.required_ruby_version = '>= 2.5.0'
  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

  # Uses exact version in case the author breaks something.
  # Please see the Gemfile for more details.
  spec.add_runtime_dependency 'nbayes'  ,'0.1.3'     # Training type of text (machine learning).
  spec.add_runtime_dependency 'nokogiri','~> 1.13'   # Hacking HTML.

  spec.add_development_dependency 'bundler' ,'~> 2.3'
  spec.add_development_dependency 'irb'     ,'~> 1.4'   # IRB rake task.
  spec.add_development_dependency 'minitest','~> 5.15'
  spec.add_development_dependency 'rake'    ,'~> 13.0'
  spec.add_development_dependency 'raketeer','~> 0.2'   # Nokogiri & IRB rake tasks.

  spec.post_install_message = <<~MSG
    +=============================================================================+
    | UncleKryon v#{UncleKryon::VERSION}
    |
    | You can now use [#{spec.executables.join(', ')}] on the command line.
    |
    | Homepage:  #{spec.homepage}
    |
    | Code:      #{spec.metadata['source_code_uri']}
    | Changelog: #{spec.metadata['changelog_uri']}
    | Bugs:      #{spec.metadata['bug_tracker_uri']}
    +=============================================================================+
  MSG
end
