# encoding: UTF-8
# frozen_string_literal: true

require_relative 'lib/unclekryon/version'

Gem::Specification.new do |spec|
  spec.name        = 'unclekryon'
  spec.version     = UncleKryon::VERSION
  spec.authors     = ['Bradley Whited']
  spec.email       = ['code@esotericpig.com']
  spec.licenses    = ['GPL-3.0-or-later']
  spec.homepage    = 'https://github.com/esotericpig/UncleKryon-server'
  spec.summary     = 'Uncle Kryon server (& hacker).'
  spec.description = 'Uncle Kryon server (& hacker) for the Uncle Kryon mobile apps.'

  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'homepage_uri'          => 'https://github.com/esotericpig/UncleKryon-server',
    'source_code_uri'       => 'https://github.com/esotericpig/UncleKryon-server',
    'changelog_uri'         => 'https://github.com/esotericpig/UncleKryon-server/releases',
    'bug_tracker_uri'       => 'https://github.com/esotericpig/UncleKryon-server/issues',
  }

  spec.required_ruby_version = '>= 3.1'
  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

  spec.require_paths = ['lib']
  spec.bindir        = 'bin'
  spec.executables   = [spec.name]

  spec.files = [
    Dir.glob("{#{spec.require_paths.join(',')}}/**/*.{erb,rb}"),
    Dir.glob("#{spec.bindir}/*"),
    Dir.glob('{spec,test}/**/*.{erb,rb}'),
    Dir.glob('{hax,iso,train}/**/*.{yaml,yml}'),
    %W[Gemfile Gemfile.lock #{spec.name}.gemspec Rakefile],
    %w[LICENSE README.md],
  ].flatten

  # Using exact version in case the author breaks something (see Gemfile for more details).
  spec.add_dependency 'nbayes'  ,'0.1.3' # Training type of text (machine learning).
  spec.add_dependency 'nokogiri','~> 1'  # Hacking HTML.

  spec.post_install_message = <<~MSG
    +=============================================================================+
    | UncleKryon v#{UncleKryon::VERSION}
    |
    | You can now use [#{spec.executables.join(', ')}] on the command line.
    |
    | Homepage:  #{spec.homepage}
    | Code:      #{spec.metadata['source_code_uri']}
    | Changelog: #{spec.metadata['changelog_uri']}
    | Bugs:      #{spec.metadata['bug_tracker_uri']}
    +=============================================================================+
  MSG
end
