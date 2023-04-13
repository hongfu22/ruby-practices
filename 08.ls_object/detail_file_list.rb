# frozen_string_literal: true

require 'etc'
require 'optparse'
require './file_list'

class DetailFileList < FileList
  def initialize(file_path, options)
    super
    file_path = File.expand_path(file_path) << '/'
    calc_block_size(file_path)
    @file_list = produce_file_info(@file_list, file_path)
  end

  def produce_file_info(file_list, file_path)
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    file_list.map do |file|
      target_file = file_path + file
      [
        File.ftype(target_file)[0],
        transform_permission(File.stat(target_file).mode.to_s(8)[-3..]),
        File.stat(target_file).nlink.to_s,
        Etc.getpwuid(File.stat(target_file).uid).name,
        Etc.getgrgid(File.stat(target_file).gid).name,
        File.size(target_file).to_s,
        File.mtime(target_file) >= half_year_ago ? File.mtime(target_file).strftime('%_m %_d %H:%M') : File.mtime(target_file).strftime('%_m %_d  %_Y'),
        File.basename(target_file)
      ]
    end
  end

  def produce_file_lists
    each_info_longest_length = check_each_info_length
    # 出力用に行ごとに文字列に纏め配列に格納する
    edit_output_format(each_info_longest_length)
    # ターミナルに出力する
    output_file_list
  end

  def check_each_info_length
    each_info_longest_length = [0, 0, 0, 0]
    @file_list.each do |file|
      each_info_longest_length[0] = file[2].length if each_info_longest_length[0] < file[2].length
      each_info_longest_length[1] = file[3].length if each_info_longest_length[1] < file[3].length
      each_info_longest_length[2] = file[4].length if each_info_longest_length[2] < file[4].length
      each_info_longest_length[3] = file[5].length if each_info_longest_length[3] < file[5].length
    end
    each_info_longest_length
  end

  def edit_output_format(each_info_longest_length)
    @file_list =
      @file_list.map do |file|
        [
          file[0] == 'f' ? '-' : file[0],
          file[1],
          file[2].rjust(each_info_longest_length[0]),
          file[3].ljust(each_info_longest_length[1] + 1),
          file[4].ljust(each_info_longest_length[2] + 1),
          file[5].rjust(each_info_longest_length[3]),
          file[6],
          file[7]
        ]
      end
  end

  def calc_block_size(file_path)
    block_size = @file_list.sum do |file|
      File::Stat.new(file_path + file).blocks
    end
    puts "total #{block_size}"
  end

  def output_file_list
    format = "%s%s %s %s %s %s %s %s\n"

    # ファイル情報の表示
    @file_list.each { |file| printf(format, *file) }
  end

  def transform_permission(characters)
    permission = ''
    permission_types = {
      '0' => '---',
      '1' => '--x',
      '2' => '-w-',
      '3' => '-wx',
      '4' => 'r--',
      '5' => 'r-x',
      '6' => 'rw-',
      '7' => 'rwx'
    }
    characters.split('').each do |character|
      permission += permission_types[character]
    end
    permission
  end
end
