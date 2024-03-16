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
    puts 'ヘルプと入力すると検索したいエラーメッセージ一覧を表示します！'
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
  japanese = %w[切断 サービス拒否 コード番号 停止].map!(&:freeze).freeze
  help = %w[ヘルプ 出口].map!(&:freeze).freeze

  WORDS = (help + japanese).map!(&:freeze).freeze

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
切断

サービス拒否

コード番号

停止

終了するとき、出口と入力します

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
    elsif line.match?(japanese[0])
      puts ''
      puts 'デバッグアダプターが切断されました'
      puts ''
      puts 'rdbg との接続が切断されました。'
      puts ''
      print '> '

    elsif line.match?(japanese[1])
      puts ''

      ECONNREFUSED = <<~EOS.chomp
        Couldn't connect to 127.0.0.1:38698: ECONNREFUSED

        neoruby-debugger 上で、

        初回起動時に表示されるメッセージです。

        複数回起動するとメッセージは流れなくなります。

        Ubuntu20.04、Windows11 homeで上記のエラーメッセージが発生します。

        MacOS Sonoma では発生しませんでした。
      EOS

      puts ECONNREFUSED
      puts ''

    # exit code
    elsif line.match?(japanese[2])
      puts ''
      puts 'rdbg exited with code [number]'
      puts ''
      puts '1. 依存ライブラリを解決する必要がある場合があります。'
      puts ''
      puts '10. プログラムが出力できるかターミナル上で確認してください。'
      puts ''
      print '> '

    # exit code
    elsif line.match?(japanese[3])
      puts ''
      puts '停止したスレッドはありません。 動けない'
      puts ''
      puts 'UIのアイコンでデバッグ操作するとき、'
      puts 'クリックした位置がずれていると発生することがあります。'
      puts ''
      print '> '
    else
      puts ''
      puts 'There are no registered words. Check the command!'
      puts ''
      puts '登録されている単語はありません。 コマンドを確認してみよう！'
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
  puts '終了するとき、出口と入力します'
  puts ''
end

__END__
