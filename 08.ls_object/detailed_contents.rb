# frozen_string_literal: true

require 'etc'
require_relative './contents_producer'

class DetailedContents
  include ContentsProducer

  def initialize(input_target, options)
    @target_contents = fetch_contents(input_target, options)
    @total_block_size = 0
    @input_target = input_target
    @input_path = Dir.exist?(input_target) ? "#{File.expand_path(input_target)}/" : ''
  end

  def produce_target_details
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @input_target)
      return
    end

    target_details = produce_targets_info
    each_info_max_length = calculate_each_info_max_length(target_details)
    formatted_target_details = format_target_details(target_details, each_info_max_length)
    output_target_details(formatted_target_details)
  end

  private

  def produce_targets_info
    half_year_ago = Time.new - 24 * 60 * 60 * 180
    @target_contents.map do |target_content|
      target_content = @input_path + target_content
      target_info = File.stat(target_content)
      @total_block_size += target_info.blocks
      {
        target_type: target_info.ftype[0],
        target_permission: transform_permission(target_info.mode.to_s(8)[-3..]),
        nlink: target_info.nlink.to_s,
        target_user_name: Etc.getpwuid(target_info.uid).name,
        target_group_name: Etc.getgrgid(target_info.gid).name,
        target_size: target_info.size.to_s,
        created_time: target_info.mtime >= half_year_ago ? target_info.mtime.strftime('%_m %_d %H:%M') : target_info.mtime.strftime('%_m %_d  %_Y'),
        basename: @target_contents.size == 1 && FileTest.file?(target_content) ? @input_target : File.basename(target_content)
      }
    end
  end

  def calculate_each_info_max_length(target_details)
    {
      nlink_length: target_details.map { |target_detail| target_detail[:nlink].length }.max,
      user_name_length: target_details.map { |target_detail| target_detail[:target_user_name].length }.max,
      group_name_length: target_details.map { |target_detail| target_detail[:target_group_name].length }.max,
      target_size_length: target_details.map { |target_detail| target_detail[:target_size].length }.max
    }
  end

  def format_target_details(target_details, each_info_max_length)
    target_details.map do |target_detail|
      [
        (target_detail[:target_type] == 'f' ? '-' : target_detail[:target_type]) + target_detail[:target_permission],
        target_detail[:nlink].rjust(each_info_max_length[:nlink_length] + 1),
        target_detail[:target_user_name].ljust(each_info_max_length[:user_name_length] + 1),
        target_detail[:target_group_name].ljust(each_info_max_length[:group_name_length] + 1),
        target_detail[:target_size].rjust(each_info_max_length[:target_size_length]),
        target_detail[:created_time],
        target_detail[:basename]
      ]
    end
  end

  def output_target_details(formatted_target_details)
    puts "total #{@total_block_size}" if Dir.exist?(@input_path)
    formatted_target_details.each do |formatted_detail|
      print("#{formatted_detail.join(' ')}\n")
    end
  end

  def transform_permission(permission_numbers)
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
    permission_numbers.gsub(/[0-7]/, permission_types)
  end
end
