# frozen_string_literal: true

# The new instance will be deleted after process ends.
class MiniTestFile
  attr_reader :mini_test

  # Default encoding utf8, Encoding change here.
  def encoding_style
    Encoding.default_internal = 'UTF-8'
    Encoding.default_external = 'UTF-8'
  end

  def initialize
    encoding_style

    ja = 'ja'.to_s
    en = 'en'.to_s
    input = ARGV[0].to_s
    output = /#{input}/o

    if ARGV[0].nil?
      @mini_test = require "#{File.dirname(__FILE__)}/error/error_en.rb"
    elsif ja.match(output) || {}[:match]
      @mini_test = require "#{File.dirname(__FILE__)}/error/error_ja.rb"
    elsif en.match(output) || {}[:match]
      @mini_test = require "#{File.dirname(__FILE__)}/error/error_en.rb"
    else
      @mini_test = puts 'Please enter ja or en as an argument.'
    end
  end

  def remove
    remove_instance_variable(:@mini_test)
  end
end

# About Exception, begin ~ rescue ~ ensure.
begin
  MiniTestFile.new.remove
rescue StandardError => e
  puts e.backtrace
ensure
  GC.compact
end

__END__
