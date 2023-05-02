# frozen_string_literal: true

require 'etc'

class DetailedlFileInfo
  def initialize(target_path, options)
    @target_list = options['a'] ? Dir.glob('*', File::FNM_DOTMATCH, base: target_path) : Dir.glob('*', base: target_path)
    @original_target_path = target_path
    @target_path = Dir.exist?(target_path) ? File.expand_path(target_path) << '/' : ''
    @block_size = calc_block_size if Dir.exist?(target_path)
    @target_list.insert(1, '..') if options['a'] && Dir.exist?(target_path)
    @target_list.reverse! if options['r']
    @target_list << target_path if FileTest.file?(target_path)
  end

  def produce_info_lists
    return puts format('ls.rb: %s: No such file or directory', @original_target_path) unless File.exist?(@original_target_path)

    informed_target_list = produce_target_info
    each_info_longest_length = check_each_info_length(informed_target_list)
    edited_target_list = edit_output_format(informed_target_list, each_info_longest_length)
    output_info_lists(edited_target_list)
  end

  private

  def produce_target_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    @target_list.map do |target|
      target_obj = @target_path + target
      target_created_time = File.mtime(target_obj)
      target_info = File.stat(target_obj)
      {
        target_type: File.ftype(target_obj)[0],
        target_permission: transform_permission(target_info.mode.to_s(8)[-3..]),
        nlink: target_info.nlink.to_s,
        target_user_name: Etc.getpwuid(target_info.uid).name,
        target_group_name: Etc.getgrgid(target_info.gid).name,
        target_size: File.size(target_obj).to_s,
        created_time: target_created_time >= half_year_ago ? target_created_time.strftime('%_m %_d %H:%M') : target_created_time.strftime('%_m %_d  %_Y'),
        basename: File.basename(target_obj)
      }
    end
  end

  def check_each_info_length(informed_target_list)
    each_longest_length = {
      nlink_len: 0,
      user_name_len: 0,
      group_name_len: 0,
      target_size_len: 0
    }
    informed_target_list.each do |target_info|
      each_longest_length[:nlink_len] = target_info[:nlink].length if each_longest_length[:nlink_len] < target_info[:nlink].length
      each_longest_length[:user_name_len] = target_info[:target_user_name].length if each_longest_length[:user_name_len] < target_info[:target_user_name].length
      each_longest_length[:group_name_len] = target_info[:target_group_name].length if each_longest_length[:group_name_len] < target_info[:target_group_name].length
      each_longest_length[:target_size_len] = target_info[:target_size].length if each_longest_length[:target_size_len] < target_info[:target_size].length
    end
    each_longest_length
  end

  def edit_output_format(informed_target_list, each_info_longest_length)
    edited_target_list = informed_target_list.map do |informed_target|
      [
        informed_target[:target_type] == 'f' ? '-' : informed_target[:target_type],
        informed_target[:target_permission],
        informed_target[:nlink].rjust(each_info_longest_length[:nlink_len] + 1),
        informed_target[:target_user_name].ljust(each_info_longest_length[:user_name_len] + 1),
        informed_target[:target_group_name].ljust(each_info_longest_length[:group_name_len] + 1),
        informed_target[:target_size].rjust(each_info_longest_length[:target_size_len]),
        informed_target[:created_time],
        informed_target[:basename]
      ]
    end
    edited_target_list[0][7] = @original_target unless edited_target_list.count > 1 || Dir.exist?(@target_path)
    edited_target_list
  end

  def calc_block_size
    @target_list.sum do |target|
      File::Stat.new(@target_path + target).blocks
    end
  end

  def output_info_lists(edited_target_list)
    puts "total #{@block_size}" if Dir.exist?(@target_path)
    format = "%s%s %s %s %s %s %s %s\n"
    edited_target_list.each { |target| printf(format, *target) }
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
