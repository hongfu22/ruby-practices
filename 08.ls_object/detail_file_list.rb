# frozen_string_literal: true

require 'etc'

class DirContentInfo
  def initialize(dir_path, options)
    @target_contents = []
    if options['a'] && Dir.exist?(dir_path)
      @target_contents = Dir.glob('*', File::FNM_DOTMATCH, base: dir_path) :
      @target_contents.insert(1, '..')
    else
      @target_contents = Dir.glob('*', base: dir_path)
    end
    @original_dir_path = dir_path
    @dir_path = Dir.exist?(dir_path) ? File.expand_path(dir_path) << '/' : ''
    @block_size = calc_block_size if Dir.exist?(dir_path)
    @target_contents.reverse! if options['r']
    @target_contents << dir_path if FileTest.file?(dir_path)
  end

  def produce_dir_info
    unless File.exist?(@original_dir_path)
      puts format('ls.rb: %s: No such file or directory', @original_dir_path)
      return
    end

    target_info = produce_target_info
    each_info_longest_length = check_each_info_length(target_info)
    edited_target_info = edit_output_format(target_info, each_info_longest_length)
    output_info_lists(edited_target_info)
  end

  private

  def produce_target_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    @target_contents.map do |t_content|
      target_content = @dir_path + t_content
      target_created_time = File.mtime(target_content)
      target_info = File.stat(target_content)
      {
        target_type: File.ftype(target_content)[0],
        target_permission: transform_permission(target_info.mode.to_s(8)[-3..]),
        nlink: target_info.nlink.to_s,
        target_user_name: Etc.getpwuid(target_info.uid).name,
        target_group_name: Etc.getgrgid(target_info.gid).name,
        target_size: File.size(target_content).to_s,
        created_time: target_created_time >= half_year_ago ? target_created_time.strftime('%_m %_d %H:%M') : target_created_time.strftime('%_m %_d  %_Y'),
        basename: File.basename(target_content)
      }
    end
  end

  def check_each_info_length(target_info)
    each_longest_length = {
      nlink_len: 0,
      user_name_len: 0,
      group_name_len: 0,
      target_size_len: 0
    }
    target_info.each do |t_info|
      each_longest_length[:nlink_len] = t_info[:nlink].length if each_longest_length[:nlink_len] < t_info[:nlink].length
      each_longest_length[:user_name_len] = t_info[:target_user_name].length if each_longest_length[:user_name_len] < t_info[:target_user_name].length
      each_longest_length[:group_name_len] = t_info[:target_group_name].length if each_longest_length[:group_name_len] < t_info[:target_group_name].length
      each_longest_length[:target_size_len] = t_info[:target_size].length if each_longest_length[:target_size_len] < t_info[:target_size].length
    end
    each_longest_length
  end

  def edit_output_format(target_info, each_info_longest_length)
    edited_target_info = target_info.map do |t_info|
      [
        t_info[:target_type] == 'f' ? '-' : t_info[:target_type],
        t_info[:target_permission],
        t_info[:nlink].rjust(each_info_longest_length[:nlink_len] + 1),
        t_info[:target_user_name].ljust(each_info_longest_length[:user_name_len] + 1),
        t_info[:target_group_name].ljust(each_info_longest_length[:group_name_len] + 1),
        t_info[:target_size].rjust(each_info_longest_length[:target_size_len]),
        t_info[:created_time],
        t_info[:basename]
      ]
    end
    edited_target_info[0][7] = @original_target unless edited_target_info.count > 1 || Dir.exist?(@dir_path)
    edited_target_info
  end

  def calc_block_size
    @target_contents.sum do |target|
      File::Stat.new(@dir_path + target).blocks
    end
  end

  def output_info_lists(edited_target_contents)
    puts "total #{@block_size}" if Dir.exist?(@dir_path)
    format = "%s%s %s %s %s %s %s %s\n"
    edited_target_contents.each { |target| printf(format, *target) }
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
