# encoding: utf-8
# frozen_string_literal: true

source 'https://rubygems.org'

# NOTE: In case the author doesn't update it again, leaving this code here for possible use in the future.
#
# For training type of text (machine learning).
# - nbayes Gem is out-of-date, so must use GitHub.
# - ":git" with "https" is used instead of ":github" for security.
# - Use "bundle list" (not "gem list") to see it.
#gem 'nbayes',git: 'https://github.com/oasic/nbayes.git',ref: '3dd46bd'

gemspec

group :development,:test do
  gem 'bundler' ,'~> 2.6'
  gem 'rake'    ,'~> 13.3'

  gem 'irb'     ,'~> 1.15' # IRB rake task.
  gem 'raketeer','~> 0.2'  # Nokogiri & IRB rake tasks.
end

group :test do
  gem 'minitest','~> 5.25'
end
