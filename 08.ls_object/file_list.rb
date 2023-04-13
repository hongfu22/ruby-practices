# frozen_string_literal: true

require 'etc'
require 'optparse'

class FileList
  TAB_LENGTH = 8

  def initialize(file_path, options)
    @row_len = 3
    @options = options
    @file_list =
      if options['a']
        Dir.glob('*', File::FNM_DOTMATCH, base: file_path)
      else
        Dir.glob('*', base: file_path)
      end
    @file_list.insert(1, '..') if options['a']
    @file_list.reverse! if @options['r']
  end

  def produce_file_lists(row_len = @row_len)
    return nil if @file_list.length.zero?

    # 列数の指定が1の場合はそのままファイルの配列を出力
    return output_file_list if row_len == 1

    # 行数
    col_num = (@file_list.length / row_len.to_f).ceil
    # ファイルパスの最長の長さを格納、後にこの長さにパスの長さを合わせる
    max_length = cal_longest_file_name(col_num)
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    return produce_file_lists(@row_len -= 1) if inspect_column_width?(max_length)

    # 出力用に行ごとに文字列に纏め配列に格納する
    @file_list = produce_each_column_array(col_num, max_length)
    # ターミナルに出力する
    output_file_list
  end

  # 行毎にパスを纏め配列にする
  def produce_each_column_array(col_num, max_length)
    output_list = []
    # 行数分だけ繰り返し各行の要素を加工
    col_num.times do |column|
      # 対象行(column)の各列(target_num)のファイルパスを取り出し格納する
      each_columns = []
      column.step(@file_list.length, col_num) do |target_num|
        unless @file_list[target_num].nil?
          # 一番長い文字に合わせて左詰めに整形し格納する
          each_columns << format("%-#{max_length}s", @file_list[target_num])
        end
      end
      # １行にタブで区切って連結
      output_list << each_columns.join("\t")
    end
    output_list
  end

  # 各列ごとに一番長い文字列の文字数を取得する
  def cal_longest_file_name(col_num)
    max_length = 0
    # 指定されている列数ごとにパスの配列を順番に分け各列の最長文字数を取得
    @file_list.each_slice(col_num) do |files_in_a_row|
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
    name.length + name.chars.count { |letter| !letter.ascii_only? }
  end

  def inspect_column_width?(max_length)
    # タブの長さを計算、文字数のTAB_LENGTHまでの倍数の差が長さになる
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    # １行の幅を計算、タブの数（列数-1）と列数分の最大文字数
    row_width = tab_width * (@row_len - 1) + max_length * @row_len
    # １行分を連結した幅がコマンドラインの幅よりも大きい場合は列数を少なくして再度関数呼び出し
    row_width >= `tput cols`.to_i
  end

  def output_file_list
    @file_list.each { |file| puts file }
  end
end
