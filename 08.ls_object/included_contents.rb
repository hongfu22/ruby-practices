# frozen_string_literal: true

require_relative './contents_producer'

class IncludedContents
  include ContentsProducer

  TAB_LENGTH = 8
  private_constant :TAB_LENGTH

  def initialize(input_target, options)
    @column_number = 3
    @input_target = input_target
    @target_contents = fetch_contents(input_target, options)
  end

  def produce_within_target(column_number = @column_number)
    if @target_contents.nil?
      puts format('ls.rb: %s: No such file or directory', @input_target)
      return
    end

    if column_number == 1 || @target_contents.empty?
      output_within_target(@target_contents)
      return
    end

    row_count = (@target_contents.length / column_number.to_f).ceil
    max_length = calculate_max_file_name_length
    if too_wide_row?(max_length)
      produce_within_target(@column_number -= 1)
      return
    end

    rows = produce_rows(row_count, max_length)
    output_within_target(rows)
  end

  private

  def produce_rows(row_count, max_length)
    rows = []
    row_count.times do |row_number|
      row = []
      row_number.step(@target_contents.length, row_count) do |target_number|
        row << format("%-#{max_length}s", @target_contents[target_number]) unless @target_contents[target_number].nil?
      end
      rows << row.join("\t")
    end
    rows
  end

  def calculate_max_file_name_length
    @target_contents.map(&:length).max
  end

  def too_wide_row?(max_length)
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    row_width = tab_width * (@column_number - 1) + max_length * @column_number
    row_width >= `tput cols`.to_i
  end

  def output_within_target(rows)
    rows.each { |row| puts row }
  end
end
