#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

opt = OptionParser.new
argv = opt.parse!(ARGV)
# ファイル指定が無ければカレントディレクトリ、あれば指定したパスを取得
file_path = argv.empty? ? './' : argv[0]

class FileList
  TAB_LENGTH = 8

  attr_accessor :row
  attr_reader :file_path

  def initialize(file_path, row)
    @file_path = file_path
    @row = row.floor.to_f
    # パス内の.始まりを除いたファイル、ディレクトリを取得
    @files = Dir.glob('*'.encode('utf-8'), base: @file_path)
  end

  # 起点メソッド
  def main(row = @row)
    return nil if @files.size.zero?
    # 列数の指定が1の場合はそのままファイルの配列を出力
    return output_list(@files) if row.to_i == 1

    # 行数
    col_num = (@files.size / row).ceil
    # ファイルパスの最長の長さを格納、後にこの長さにパスの長さを合わせる
    max_length = fetch_max_name_length(col_num, @files)
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    return main(@row -= 1) if inspect_column_width?(max_length)

    # 出力用に行ごとに文字列に纏め配列に格納する
    output_file_array = produce_each_column_array(col_num, max_length, @files)
    # ターミナルに出力する
    output_list(output_file_array)
  end

  def output_list(files)
    files.each { |file| puts file }
  end

  # 各列ごとに一番長い文字列の文字数を取得する
  def fetch_max_name_length(col_num, files)
    max_length = 0
    # 指定されている列数ごとにパスの配列を順番に分け各列の最長文字数を取得
    files.each_slice(col_num) do |file|
      file.each do |f|
        # ファイル名の長さをはかる
        length = measure_name_width(f)
        max_length = length if max_length < length
      end
    end
    max_length
  end

  # 日本語を2文字としてカウントする関数
  def measure_name_width(name)
    # ファイル名のサイズ（全て半角）と日本語の全角で出る余分な半角分を足してパスの長さとする
    name.size + name.chars.count { |letter| letter.ascii_only? == false }
  end

  def inspect_column_width?(max_length)
    # タブの長さを計算、文字数のTAB_LENGTHまでの倍数の差が長さになる
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    # １行の幅を計算、タブの数（列数-1）と列数分の最大文字数
    row_width = tab_width * (@row - 1) + max_length * @row
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    true if row_width >= `tput cols`.to_i
  end

  # 行毎にパスを纏め配列にする
  def produce_each_column_array(col_num, max_length, files)
    path_list = []
    # 行数分だけ繰り返し各行の要素を加工
    col_num.times do |column|
      # 対象行(column)の各列(target_num)のファイルパスを取り出し格納する
      each_row_array = []
      column.step(files.length, col_num) do |target_num|
        unless files[target_num].nil?
          # 一番長い文字に合わせて左詰めに整形し格納する
          each_row_array << format("%-#{max_length}s", files[target_num])
        end
      end
      # １行にタブで区切って連結
      path_list << each_row_array.join("\t")
    end
    path_list
  end
end

if Dir.exist?(file_path)
  file_list = FileList.new(file_path, 3)
  file_list.main
elsif File.exist?(file_path)
  puts file_path
else
  puts format('ls.rb: %s: No such file or directory', file_path)
end
