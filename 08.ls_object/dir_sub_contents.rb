# frozen_string_literal: true

require_relative './contents_producer'

class DirSubContents
  include ContentsProducer

  TAB_LENGTH = 8
  private_constant :TAB_LENGTH

  def initialize(input_target, options)
    @col_num = 3
    @input_target = input_target
    @target_contents = fetch_contents(input_target, options)
  end

  def produce_within_target(col_num = @col_num)
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @input_target)
      return
    end

    if col_num == 1 || @target_contents.empty?
      output_sub_contents(@target_contents)
      return
    end

    row_count = (@target_contents.length / col_num.to_f).ceil
    max_length = calculate_longest_file_name_length
    if too_wide_row?(max_length)
      produce_within_target(@col_num -= 1)
      return
    end

    rows = produce_each_row(row_count, max_length)
    output_sub_contents(rows)
  end

  private

  def produce_each_row(row_count, max_length)
    rows = []
    row_count.times do |row|
      each_row = []
      row.step(@target_contents.length, row_count) do |target_num|
        each_row << format("%-#{max_length}s", @target_contents[target_num]) unless @target_contents[target_num].nil?
      end
      rows << each_row.join("\t")
    end
    rows
  end

  def calculate_longest_file_name_length
    @target_contents.map(&:length).max
  end

  def too_wide_row?(max_length)
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    row_width = tab_width * (@col_num - 1) + max_length * @col_num
    row_width >= `tput cols`.to_i
  end

  def output_sub_contents(rows)
    rows.each { |row| puts row }
  end
end
