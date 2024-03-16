#!/usr/bin/env ruby
# frozen_string_literal: true

# frozen_englishing_literal: true

# vim: filetype=ruby

require 'readline'

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

class Speak
  def self.communicate
    puts ''
    puts 'Type help to see the error message!'
    puts ''
  end
end

begin
  Speak.communicate
rescue StandardError => e
  puts e.backtrace
ensure
  GC.compact
end

# Search words
begin
  english = %w[discconect ECONNREFUSED code_number Stopped].map!(&:freeze).freeze
  help = %w[help exit].map!(&:freeze).freeze

  WORDS = (english + help).map!(&:freeze).freeze

  Readline.completion_proc = proc { |word|
    WORDS.grep(/\A#{Regexp.quote word}/)
  }

  print '> '

  # readline
  while (line = Readline.readline(''))

    line.chomp!

    # help message.
    if line.match?(help[0])
      puts ''
      puts 'ERROR MESSAGE'.center(60, '-')

      puts "
discconect

ECONNREFUSED

code_number

Stopped

When finished, type exit

"

      puts 'ERROR MESSAGE'.center(60, '-')
      puts ''

      print '> '

    # search words exit!
    elsif line.match?(help[1])
      begin
        exit!
      rescue StandardError => e
        puts e.backtrace
      ensure
        GC.compact
      end

    # rdbg disconnect.
    elsif line.match?(english[0])
      puts ''
      puts 'Debug adapter discconected'
      puts ''
      puts 'Connection with rdbg has been broken.'
      puts ''
      print '> '

    elsif line.match?(english[1])
      puts ''

      ECONNREFUSED = <<~EOS.chomp
        Couldn't connect to 127.0.0.1:38698: ECONNREFUSED

        On neoruby-debugger,

        This is the message that appears when you start for the first time.

        If you start multiple times, the message will not flow.

        The above error message is occurred on Ubuntu20.04 and Windows11 home.

        It did not occur on MacOS Sonoma.
      EOS

      puts ECONNREFUSED
      puts ''

    # exit code
    elsif line.match?(english[2])
      puts ''
      puts 'rdbg exited with code [number]'
      puts ''
      puts '1. Depending on the function, dependent libraries may need to be resolved.'
      puts ''
      puts '10. Please check on the terminal whether the program can output.'
      puts ''
      print '> '
    # exit code
    elsif line.match?(english[3])
      puts ''
      puts 'No stopped thread. Cannot move'
      puts ''
      puts 'This may occur if the clicked position is shifted when debugging the UI icon.'
      puts ''
      print '> '
    else
      puts ''
      puts 'There are no registered words. Check the command!'
      puts ''
      print '> '
    end
  end

# Exception throw!
rescue StandardError => e
  puts e.backtrace
  retry

# Ruby ensure is Java Exception of finally.
ensure
  puts ''
  puts 'When finished, type exit!'
  puts ''
end

__END__
