# frozen_string_literal: true

class FileList
  TAB_LENGTH = 8
  private_constant :TAB_LENGTH

  def initialize(target_path, options)
    @row_len = 3
    @original_target = target_path
    @file_list = options['a'] ? Dir.glob('*', File::FNM_DOTMATCH, base: target_path) : Dir.glob('*', base: target_path)
    @file_list.insert(1, '..') if options['a'] && Dir.exist?(target_path)
    @file_list.reverse! if options['r']
    @file_list << target_path if FileTest.file?(target_path)
  end

  def produce_file_lists(row_len = @row_len)
    return puts format('ls.rb: %s: No such file or directory', @original_target) unless File.exist?(@original_target)

    return output_file_list(@file_list) if row_len == 1 || @file_list.empty?

    col_num = (@file_list.length / row_len.to_f).ceil
    max_length = cal_longest_file_name
    return produce_file_lists(@row_len -= 1) if inspect_column_width?(max_length)

    combined_file_list = produce_each_column_array(col_num, max_length)
    output_file_list(combined_file_list)
  end

  private

  def produce_each_column_array(col_num, max_length)
    combined_file_list = []
    col_num.times do |column|
      each_columns = []
      column.step(@file_list.length, col_num) do |target_num|
        each_columns << format("%-#{max_length}s", @file_list[target_num]) unless @file_list[target_num].nil?
      end
      combined_file_list << each_columns.join("\t")
    end
    combined_file_list
  end

  def cal_longest_file_name
    @file_list.map(&:length).max
  end

  def measure_name_width(name)
    name.length + name.chars.count { |letter| !letter.ascii_only? }
  end

  def inspect_column_width?(max_length)
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    row_width = tab_width * (@row_len - 1) + max_length * @row_len
    row_width >= `tput cols`.to_i
  end

  def output_file_list(combined_file_list)
    combined_file_list.each { |combined_files| puts combined_files }
  end
end
