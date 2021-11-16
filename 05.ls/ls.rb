#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

opt = OptionParser.new
# オプション格納用ハッシュ
command_line_arguments = {}
opt.on('-a') { |option| command_line_arguments[:a] = option }
opt.on('-r') { |option| command_line_arguments[:r] = option }
# オプション外の引数を取得
argv = opt.parse!(ARGV)
# ファイル指定が無ければカレントディレクトリ、あれば指定したパスを取得
file_path = argv.empty? ? './' : argv[0]

class FileList
  TAB_LENGTH = 8
  def initialize(file_path, row, command_line_arguments = {})
    @row = row
    @files =
      if command_line_arguments[:a]
        # -aのオプションが指定されていた場合
        Dir.glob('*', File::FNM_DOTMATCH, base: file_path)
      else
        # パス内の.始まりを除いたファイル、ディレクトリを取得
        Dir.glob('*', base: file_path)
      end
    @files.reverse! if command_line_arguments[:r]
  end

  # 起点メソッド
  def produce_file_lists(row = @row)
    return nil if @files.size.zero?
    # 列数の指定が1の場合はそのままファイルの配列を出力
    return output_list(@files) if row == 1

    # 行数
    col_num = (@files.size / row.to_f).ceil
    # ファイルパスの最長の長さを格納、後にこの長さにパスの長さを合わせる
    max_length = fetch_max_name_length(col_num, @files)
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    return produce_file_lists(@row -= 1) if inspect_column_width?(max_length)

    # 出力用に行ごとに文字列に纏め配列に格納する
    output_files = produce_each_column_array(col_num, max_length, @files)
    # ターミナルに出力する
    output_list(output_files)
  end

  private

  def output_list(files)
    files.each { |file| puts file }
  end

  # 各列ごとに一番長い文字列の文字数を取得する
  def fetch_max_name_length(col_num, files)
    max_length = 0
    # 指定されている列数ごとにパスの配列を順番に分け各列の最長文字数を取得
    files.each_slice(col_num) do |files_in_a_row|
      files_in_a_row.each do |file|
        # ファイル名の長さをはかる
        length = measure_name_width(file)
        max_length = length if max_length < length
      end
    end
    max_length
  end

  # 日本語を2文字としてカウントする関数
  def measure_name_width(name)
    # ファイル名のサイズ（全て半角）と日本語の全角で出る余分な半角分を足してパスの長さとする
    name.size + name.chars.count { |letter| !letter.ascii_only? }
  end

  def inspect_column_width?(max_length)
    # タブの長さを計算、文字数のTAB_LENGTHまでの倍数の差が長さになる
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    # １行の幅を計算、タブの数（列数-1）と列数分の最大文字数
    row_width = tab_width * (@row - 1) + max_length * @row
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    row_width >= `tput cols`.to_i
  end

  # 行毎にパスを纏め配列にする
  def produce_each_column_array(col_num, max_length, files)
    path_list = []
    # 行数分だけ繰り返し各行の要素を加工
    col_num.times do |column|
      # 対象行(column)の各列(target_num)のファイルパスを取り出し格納する
      each_rows = []
      column.step(files.length, col_num) do |target_num|
        unless files[target_num].nil?
          # 一番長い文字に合わせて左詰めに整形し格納する
          each_rows << format("%-#{max_length}s", files[target_num])
        end
      end
      # １行にタブで区切って連結
      path_list << each_rows.join("\t")
    end
    path_list
  end
end

if Dir.exist?(file_path)
  file_list = FileList.new(file_path, 3, command_line_arguments)
  file_list.produce_file_lists
elsif File.exist?(file_path)
  puts file_path
else
  puts format('ls.rb: %s: No such file or directory', file_path)
end
