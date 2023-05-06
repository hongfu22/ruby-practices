# frozen_string_literal: true

require 'etc'
require_relative './content_producer'

class DirInfo
  include ContentProducer
  def initialize(dir_path, options)
    @target_contents = fetch_contents(dir_path, options)
    @original_dir_path = dir_path
    @dir_path = Dir.exist?(dir_path) ? File.expand_path(dir_path) << '/' : ''
  end

  def produce_dir_info
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @original_dir_path)
      return
    end

    target_info, block_size = produce_target_info
    each_info_longest_length = fetch_each_info_length(target_info)
    formatted_target_info = format_target_info(target_info, each_info_longest_length)
    output_info_lists(formatted_target_info, block_size)
  end

  private

  def produce_target_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    block_size = 0
    target_info =
    @target_contents.map do |t_content|
      target_content = @dir_path + t_content
      target_info = File.stat(target_content)
      block_size += target_info.blocks
      {
        target_type: File.ftype(target_content)[0],
        target_permission: transform_permission(target_info.mode.to_s(8)[-3..]),
        nlink: target_info.nlink.to_s,
        target_user_name: Etc.getpwuid(target_info.uid).name,
        target_group_name: Etc.getgrgid(target_info.gid).name,
        target_size: target_info.size.to_s,
        created_time: target_info.mtime >= half_year_ago ? target_info.mtime.strftime('%_m %_d %H:%M') : target_info.mtime.strftime('%_m %_d  %_Y'),
        basename: @target_contents.count == 1 && FileTest.file?(@dir_path) ? @original_target : File.basename(target_content)
      }
    end
    [target_info, block_size]
  end

  def fetch_each_info_length(target_info)
    nlink_len = []
    user_name_len = []
    group_name_len = []
    target_size_len = []
    target_info.each do |t_info|
      nlink_len << t_info[:nlink].length
      user_name_len << t_info[:target_user_name].length
      group_name_len << t_info[:target_group_name].length
      target_size_len << t_info[:target_size].length
    end
    each_longest_length = {
      nlink_len: nlink_len.max,
      user_name_len: user_name_len.max,
      group_name_len: group_name_len.max,
      target_size_len: target_size_len.max
    }
    each_longest_length
  end

  def format_target_info(target_info, each_info_longest_length)
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
    edited_target_info
  end

  def output_info_lists(edited_target_contents, block_size)
    puts "total #{block_size}" if Dir.exist?(@dir_path)
    format = "%s%s %s %s %s %s %s %s\n"
    edited_target_contents.each { |target| printf(format, *target) }
  end

  def transform_permission(permission_nums)
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
    permission_nums.gsub(/[01234567]/, permission_types)
  end
end
