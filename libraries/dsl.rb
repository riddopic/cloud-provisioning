# encoding: UTF-8

require_relative 'helpers'
require_relative 'helpers_sql'
require_relative 'helpers_component'

Chef::Recipe.send(:include, Cloud::DSL)
Chef::Resource.send(:include, Cloud::DSL)
Chef::Provider.send(:include, Cloud::DSL)
