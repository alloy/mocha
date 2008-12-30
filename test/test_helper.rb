unless defined?(STANDARD_OBJECT_PUBLIC_INSTANCE_METHODS)
  STANDARD_OBJECT_PUBLIC_INSTANCE_METHODS = Object.public_instance_methods
end

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__)))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'unit'))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'unit', 'parameter_matchers'))
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), 'acceptance'))

require 'mocha/options'
if $options['use_test_unit_gem']
  require 'rubygems'
  gem 'test-unit'
end

require 'test/unit'

module Kernel
  private
  
  # TODO: Currently need to check for existence of the method.
  # This is probably because the test_helper.rb file isn't required with a constsitent path from somewhere.
  def on_macruby?
    defined? MACRUBY_VERSION
  end unless respond_to?(:on_macruby?, true)
end