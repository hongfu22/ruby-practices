# frozen_string_literal: true

class DirContent
  TAB_LENGTH = 8
  private_constant :TAB_LENGTH

  def initialize(dir_path, options)
    @row_len = 3
    @dir_path = dir_path
    @target_contents = []
    if options['a'] && Dir.exist?(dir_path)
      @target_contents = Dir.glob('*', File::FNM_DOTMATCH, base: dir_path) :
      @target_contents.insert(1, '..')
    else
      @target_contents = Dir.glob('*', base: dir_path)
    end
    @target_contents.reverse! if options['r']
    @target_contents << dir_path if FileTest.file?(dir_path)
  end

  def produce_dir_contents(row_len = @row_len)
    unless File.exist?(@dir_path)
      puts format('ls.rb: %s: No such file or directory', @dir_path)
      return
    end
    return output_dir_contents(@target_contents) if row_len == 1 || @target_contents.empty?

    col_num = (@target_contents.length / row_len.to_f).ceil
    max_length = cal_longest_file_name
    return produce_dir_contents(@row_len -= 1) if is_too_long?(max_length)

    combined_target_contents = produce_each_column(col_num, max_length)
    output_dir_contents(combined_target_contents)
  end

  private

  def produce_each_column(col_num, max_length)
    combined_target_contents = []
    col_num.times do |column|
      each_columns = []
      column.step(@target_contents.length, col_num) do |target_num|
        each_columns << format("%-#{max_length}s", @target_contents[target_num]) unless @target_contents[target_num].nil?
      end
      combined_target_contents << each_columns.join("\t")
    end
    combined_target_contents
  end

  def cal_longest_file_name
    @target_contents.map(&:length).max
  end

  def is_too_long?(max_length)
    tab_width = TAB_LENGTH - max_length % TAB_LENGTH
    row_width = tab_width * (@row_len - 1) + max_length * @row_len
    row_width >= `tput cols`.to_i
  end

  def output_dir_contents(combined_target_contents)
    combined_target_contents.each { |combined_contents| puts combined_contents }
  end
end
