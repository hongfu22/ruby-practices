# frozen_string_literal: true

require 'etc'

class DetailFileList
  def initialize(target_path, options)
    @file_list = options['a'] ? Dir.glob('*', File::FNM_DOTMATCH, base: target_path) : Dir.glob('*', base: target_path)
    @original_target = target_path
    @target_path = Dir.exist?(target_path) ? File.expand_path(target_path) << '/' : ''
    @block_size = calc_block_size if Dir.exist?(target_path)
    @file_list.insert(1, '..') if options['a'] && Dir.exist?(target_path)
    @file_list.reverse! if options['r']
    @file_list << target_path if FileTest.file?(target_path)
  end

  def produce_file_lists
    return puts format('ls.rb: %s: No such file or directory', @original_target) unless File.exist?(@original_target)

    informed_file_list = produce_file_info
    each_info_longest_length = check_each_info_length(informed_file_list)
    edited_file_list = edit_output_format(informed_file_list, each_info_longest_length)
    output_file_list(edited_file_list)
  end

  private

  def produce_file_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    @file_list.map do |file|
      target_file = @target_path + file
      file_created_time = File.mtime(target_file)
      file_info = File.stat(target_file)
      {
        file_type: File.ftype(target_file)[0],
        file_permission: transform_permission(file_info.mode.to_s(8)[-3..]),
        nlink: file_info.nlink.to_s,
        file_user_name: Etc.getpwuid(file_info.uid).name,
        file_group_name: Etc.getgrgid(file_info.gid).name,
        file_size: File.size(target_file).to_s,
        created_time: file_created_time >= half_year_ago ? file_created_time.strftime('%_m %_d %H:%M') : file_created_time.strftime('%_m %_d  %_Y'),
        basename: File.basename(target_file)
      }
    end
  end

  def check_each_info_length(informed_file_list)
    each_longest_length = {
      nlink_len: 0,
      user_name_len: 0,
      group_name_len: 0,
      file_size_len: 0
    }
    informed_file_list.each do |file_info|
      each_longest_length[:nlink_len] = file_info[:nlink].length if each_longest_length[:nlink_len] < file_info[:nlink].length
      each_longest_length[:user_name_len] = file_info[:file_user_name].length if each_longest_length[:user_name_len] < file_info[:file_user_name].length
      each_longest_length[:group_name_len] = file_info[:file_group_name].length if each_longest_length[:group_name_len] < file_info[:file_group_name].length
      each_longest_length[:file_size_len] = file_info[:file_size].length if each_longest_length[:file_size_len] < file_info[:file_size].length
    end
    each_longest_length
  end

  def edit_output_format(informed_file_list, each_info_longest_length)
    edited_file_list = informed_file_list.map do |informed_file|
      [
        informed_file[:file_type] == 'f' ? '-' : informed_file[:file_type],
        informed_file[:file_permission],
        informed_file[:nlink].rjust(each_info_longest_length[:nlink_len] + 1),
        informed_file[:file_user_name].ljust(each_info_longest_length[:user_name_len] + 1),
        informed_file[:file_group_name].ljust(each_info_longest_length[:group_name_len] + 1),
        informed_file[:file_size].rjust(each_info_longest_length[:file_size_len]),
        informed_file[:created_time],
        informed_file[:basename]
      ]
    end
    edited_file_list[0][7] = @original_target unless edited_file_list.count > 1 || Dir.exist?(@target_path)
    edited_file_list
  end

  def calc_block_size
    @file_list.sum do |file|
      File::Stat.new(@target_path + file).blocks
    end
  end

  def output_file_list(edited_file_list)
    puts "total #{@block_size}" if Dir.exist?(@target_path)
    format = "%s%s %s %s %s %s %s %s\n"
    edited_file_list.each { |file| printf(format, *file) }
  end

  def transform_permission(permission_nums)
    permission = []
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
    permission_nums.chars.each do |permission_num|
      permission << permission_types[permission_num]
    end
    permission.join('')
  end
end
