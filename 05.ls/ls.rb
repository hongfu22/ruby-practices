#!/usr/bin/env ruby
# frozen_string_literal: true

require 'etc'
require 'optparse'

opt = OptionParser.new
# オプション格納用ハッシュ
command_line_arguments = {}
opt.on('-a') { |option| command_line_arguments[:a] = option }
opt.on('-r') { |option| command_line_arguments[:r] = option }
opt.on('-l') { |option| command_line_arguments[:l] = option }
# オプション外の引数を取得
argv = opt.parse!(ARGV)
# ファイル指定が無ければカレントディレクトリ、あれば指定したパスを取得
file_path = argv.empty? ? './' : argv[0]

module DetailFileList
  private

  FILE_TYPE = {
    'directory' => 'd',
    'file' => '-',
    'characterSpecial' => 'c',
    'fifo' => 'p',
    'blockSpecial' => 'b',
    'link' => 'l',
    'socket' => 's'
  }.freeze

  def fetch_detailed_file_list(files, file_path)
    absolute_path = Dir.exist?(file_path) ? File.expand_path(file_path) << '/' : ''
    files << file_path unless Dir.exist?(file_path)
    each_file_detail_info = []
    # 各列の幅を調整するための配列
    each_info_longest_length = [0, 0, 0, 0]
    files.each_with_index do |file, file_index|
      target_file = File.lstat(absolute_path + file)
      each_file_detail_info << fetch_file_detail_info(target_file).push(file)
      each_info_longest_length = check_info_length(each_info_longest_length, each_file_detail_info[file_index])
    end
    edit_file_detail_format(each_file_detail_info, each_info_longest_length)
  end

  def fetch_file_detail_info(target_file)
    file_type = FILE_TYPE[target_file.ftype]
    file_permission = produce_file_permission(target_file)
    file_detail_info = produce_file_detail_info(target_file)
    [file_type + file_permission, *file_detail_info]
  end

  def produce_file_permission(target_file)
    # パーミッション処理
    file_permission = ''
    file_permission_octal = target_file.mode.to_s(8).chars
    # 8進数にした時の各ファイルのパーミッションを表す後ろの3文字を抽出しパーミッションを判断
    file_permission_octal[-3..-1].each do |octal|
      # 2進数にして真('1')かどうかでパーミッションを判断する
      # ex) 101 => 'r-x', 011 => '-wx'
      file_permission_binary = octal.to_i.to_s(2).ljust(3, '0').chars
      file_permission_binary.each_with_index do |binary, index|
        if binary != '0'
          file_permission += 'r' if index.zero?
          file_permission += 'w' if index == 1
          file_permission += 'x' if index == 2
        else
          file_permission += '-'
        end
      end
    end
    file_permission = check_unique_permission(target_file, file_permission)
  end

  def check_unique_permission(target_file, file_permission)
    # スティッキービットとUID,GIDに関しての判断
    file_permission[-1] = edit_unique_permission('t', file_permission[-1]) if target_file.sticky?
    file_permission[-4] = edit_unique_permission('s', file_permission[-4]) if target_file.setgid?
    file_permission[-7] = edit_unique_permission('s', file_permission[-7]) if target_file.setuid?
    file_permission
  end

  def edit_unique_permission(setting_letter, source_permission)
    return setting_letter.upcase if source_permission == '-'

    setting_letter
  end

  def produce_file_detail_info(target_file)
    # その他のファイル情報
    hard_link_num = target_file.nlink.to_s
    owner =
      begin
        Etc.getpwuid(target_file.uid).name
      rescue ArgumentError
        '201'
      end
    group_owner = Etc.getgrgid(target_file.gid).name
    byte = target_file.size?.to_s
    byte = '0' if byte.empty?
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    time_stamp = target_file.mtime.strftime('%_m %_d  %_Y') if target_file.mtime < half_year_ago
    time_stamp = target_file.mtime.strftime('%_m %_d %H:%M') if target_file.mtime >= half_year_ago
    [hard_link_num, owner, group_owner, byte, time_stamp]
  end

  def check_info_length(each_info_longest_length, each_file_detail_info)
    each_info_longest_length[0] = each_file_detail_info[1].length + 1 if each_file_detail_info[1].length >= each_info_longest_length[0]
    each_info_longest_length[1] = each_file_detail_info[2].length + 1 if each_file_detail_info[2].length >= each_info_longest_length[1]
    each_info_longest_length[2] = each_file_detail_info[3].length if each_file_detail_info[3].length > each_info_longest_length[2]
    each_info_longest_length[3] = each_file_detail_info[4].length + 1 if each_file_detail_info[4].length >= each_info_longest_length[3]
    each_info_longest_length
  end

  def edit_file_detail_format(each_file_detail_info, each_info_longest_length)
    each_file_detail_info.map do |file_detail_info|
      file_detail_info[1] = file_detail_info[1].rjust(each_info_longest_length[0])
      file_detail_info[2] = file_detail_info[2].ljust(each_info_longest_length[1])
      file_detail_info[3] = file_detail_info[3].ljust(each_info_longest_length[2])
      file_detail_info[4] = file_detail_info[4].rjust(each_info_longest_length[3])
      file_detail_info.join(' ')
    end
  end

  def calculate_block_size(files, file_path)
    absolute_path = File.expand_path(file_path) << '/'
    files.map do |file|
      target_file = File.lstat(absolute_path + file)
      target_file.blocks
    end
  end
end

class FileList
  include DetailFileList

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
    return unless command_line_arguments[:l]

    puts "total #{calculate_block_size(@files, file_path).sum}" if Dir.exist?(file_path)
    @files = fetch_detailed_file_list(@files, file_path)
    @row = 1
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
  # ファイル単体指定時にも詳細表示する
  if command_line_arguments[:l]
    file_list = FileList.new(file_path, 1, command_line_arguments)
    file_list.produce_file_lists
  else
    puts file_path
  end
else
  puts format('ls.rb: %s: No such file or directory', file_path)
end
