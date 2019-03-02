require 'rubygems'
require 'bundler'
require 'json'
require 'digest'
require 'io/console'
require 'ostruct'

Bundler.require(:default)

module BooksDL; end

Dir[File.join(__dir__, 'books_dl', '**', '*.rb')].each(&method(:require))
