$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'ruby/reports'
require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'timecop'
