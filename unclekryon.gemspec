# encoding: UTF-8
# frozen_string_literal: true


require_relative 'lib/unclekryon/version'

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

  spec.required_ruby_version = '>= 2.5.0'
  spec.requirements = [
    'Nokogiri: https://www.nokogiri.org/tutorials/installing_nokogiri.html',
  ]

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

  run_dep = spec.method(:add_runtime_dependency)
  # Uses exact version in case the author breaks something.
  #   Please see the Gemfile for more details.
  run_dep[ 'nbayes'  ,'0.1.3'   ] # Training type of text (machine learning).
  run_dep[ 'nokogiri','~> 1.16' ] # Hacking HTML.

  dev_dep = spec.method(:add_development_dependency)
  dev_dep[ 'bundler' ,'~> 2.5'  ]
  dev_dep[ 'irb'     ,'~> 1.14' ] # IRB rake task.
  dev_dep[ 'minitest','~> 5.25' ]
  dev_dep[ 'rake'    ,'~> 13.2' ]
  dev_dep[ 'raketeer','~> 0.2'  ] # Nokogiri & IRB rake tasks.

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
