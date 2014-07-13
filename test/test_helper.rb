require 'simplecov'

SimpleCov.start do
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Libraries', 'lib'
  add_filter '/test/'
  add_filter 'init.rb'
  root File.expand_path(File.dirname(__FILE__) + '/../')
end if RUBY_VERSION >= '1.9.0'

# Load the normal Rails helper
require File.expand_path('../../../../test/test_helper', __FILE__)
#require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')