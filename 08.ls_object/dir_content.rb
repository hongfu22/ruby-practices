# frozen_string_literal: true
require_relative './content_producer'

class DirContent
  include ContentProducer
  TAB_LENGTH = 8
  private_constant :TAB_LENGTH

  def initialize(dir_path, options)
    @col_num = 3
    @dir_path = dir_path
    @target_contents = fetch_contents(dir_path, options)
  end

  def produce_dir_contents(col_num = @col_num)
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @dir_path)
      return
    end
    return output_dir_contents(@target_contents) if col_num == 1 || @target_contents.empty?

    row_num = (@target_contents.length / col_num.to_f).ceil
    max_length = cal_longest_file_name
    return produce_dir_contents(@col_num -= 1) if is_too_long?(max_length)

    combined_target_contents = produce_each_row(row_num, max_length)
    output_dir_contents(combined_target_contents)
  end

  private

  def produce_each_row(row_num, max_length)
    combined_target_contents = []
    row_num.times do |row|
      each_rows = []
      row.step(@target_contents.length, row_num) do |target_num|
        each_rows << format("%-#{max_length}s", @target_contents[target_num]) unless @target_contents[target_num].nil?
      end
      combined_target_contents << each_rows.join("\t")
    end
    combined_target_contents
  end

  def cal_longest_file_name
    @target_contents.map(&:length).max
  end

  def is_too_long?(max_length)
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    row_width = tab_width * (@col_num - 1) + max_length * @col_num
    row_width >= `tput cols`.to_i
  end

  def output_dir_contents(combined_target_contents)
    combined_target_contents.each { |combined_contents| puts combined_contents }
  end
end
