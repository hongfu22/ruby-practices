# frozen_string_literal: true

require 'etc'
require_relative './contents_producer'

class ContentsInfo
  include ContentsProducer

  def initialize(input_target, options)
    @target_contents = fetch_contents(input_target, options)
    @block_size = 0
    @original_target = input_target
    @input_target = Dir.exist?(input_target) ? "#{File.expand_path(input_target)}/" : ''
  end

  def produce_target_details
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @original_target)
      return
    end

    target_info = produce_target_info
    each_info_length = calculate_each_info_longest_length(target_info)
    formatted_target_info = format_target_info(target_info, each_info_length)
    output_contents_info(formatted_target_info)
  end

  private

  def produce_target_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    @target_contents.map do |target_content|
      target_content = @input_target + target_content
      target_info = File.stat(target_content)
      @block_size += target_info.blocks
      {
        target_type: target_info.ftype[0],
        target_permission: transform_permission(target_info.mode.to_s(8)[-3..]),
        nlink: target_info.nlink.to_s,
        target_user_name: Etc.getpwuid(target_info.uid).name,
        target_group_name: Etc.getgrgid(target_info.gid).name,
        target_size: target_info.size.to_s,
        created_time: target_info.mtime >= half_year_ago ? target_info.mtime.strftime('%_m %_d %H:%M') : target_info.mtime.strftime('%_m %_d  %_Y'),
        basename: @target_contents.size == 1 && FileTest.file?(target_content) ? @original_target : File.basename(target_content)
      }
    end
  end

  def calculate_each_info_longest_length(target_info)
    {
      nlink_len: target_info.map { |info| info[:nlink].length }.max,
      user_name_len: target_info.map { |info| info[:target_user_name].length }.max,
      group_name_len: target_info.map { |info| info[:target_group_name].length }.max,
      target_size_len: target_info.map { |info| info[:target_size].length }.max
    }
  end

  def format_target_info(target_info, each_info_length)
    target_info.map do |info|
      info[:target_type] = info[:target_type] == 'f' ? '-' : info[:target_type]
      info[:nlink] = info[:nlink].rjust(each_info_length[:nlink_len] + 1)
      info[:target_user_name] = info[:target_user_name].ljust(each_info_length[:user_name_len] + 1)
      info[:target_group_name] = info[:target_group_name].ljust(each_info_length[:group_name_len] + 1)
      info[:target_size] = info[:target_size].rjust(each_info_length[:target_size_len])
      info
    end
  end

  def output_contents_info(formatted_target_info)
    puts "total #{@block_size}" if Dir.exist?(@input_target)
    formatted_target_info.each do |info|
      print("#{info[:target_type]}#{info[:target_permission]} #{info[:nlink]} #{info[:target_user_name]} \
#{info[:target_group_name]} #{info[:target_size]} #{info[:created_time]} #{info[:basename]}\n")
    end
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
    permission_nums.gsub(/[0-7]/, permission_types)
  end
end
