#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

def produce_each_size_info(target_content, target_content_size, file_name = '')
  output_info = []
  output_info << count_line_numbers(target_content)
  output_info << count_word_numbers(target_content)
  output_info << target_content_size.to_s.rjust(7)
  output_info << file_name if file_name
end

def produce_line_number(target_content, file_name = '')
  output_info = []
  output_info << count_line_numbers(target_content)
  output_info << file_name if file_name
end

def count_line_numbers(target_content)
  if target_content[-1].end_with?("\n")
    target_content.length
  else
    target_content.length - 1
  end
end

def count_word_numbers(target_content)
  target_content.reject!(&:empty?)
  target_content.sum do |line|
    line_words = line.split("\s")
    line_words.length
  end
end

def produce_content_sum(each_content_count, count_row_num)
  content_count_sum =
    if each_content_count.empty?
      Array.new(count_row_num) do
        0
      end
    else
      Array.new(count_row_num) do |index|
        each_content_count.sum do |content_count|
          content_count[index].to_i
        end
      end
    end
  content_count_sum << 'total'
end

def adjust_content_alignment(each_content_count)
  each_content_count.map do |content_count|
    content_count[0] = content_count[0].to_s.rjust(8)
    content_count[1] = content_count[1].to_s.rjust(7)
    content_count[2] = content_count[2].to_s.rjust(7)
    content_count.join(' ')
  end
end

def adjust_line_content_alignment(each_content_count)
  each_content_count.map do |content_count|
    content_count[0] = content_count[0].to_s.rjust(8)
    content_count.join(' ')
  end
end

# -----ここから処理内容-----

opt = OptionParser.new
# オプション格納用ハッシュ
command_line_arguments = {}
opt.on('-l') { |option| command_line_arguments[:l] = option }
argv = opt.parse!(ARGV)

# 合計値計算のために各要素保持のための配列
each_content_count = []
# 合計値出す際、列ごとに足算する際に-lオプションの時と動作を分けるため
count_row_num = 3
# 引数がない=>標準入力
if argv.empty?
  target_content = readlines
  target_content_size = target_content.join('').size
  each_content_count <<
    if command_line_arguments[:l]
      produce_line_number(target_content)
    else
      produce_each_size_info(target_content, target_content_size)
    end
else
  argv.each do |file_name|
    begin
      File.open(file_name, 'r') do |file|
        target_content = file.readlines
        target_content_size = file.size
      end
    rescue Errno::EISDIR
      puts format("wc: #{file_name}s: read: Is a directory", file_name)
      next
    rescue Errno::ENOENT
      puts format("wc: #{file_name}s: open: No such file or directory", file_name)
      next
    end
    if command_line_arguments[:l]
      count_row_num = 1
      each_content_count << produce_line_number(target_content, file_name)
      next
    end
    each_content_count << produce_each_size_info(target_content, target_content_size, file_name)
  end
  each_content_count << produce_content_sum(each_content_count, count_row_num) if argv.length > 1
end

# ここで纏めてレイアウトを調整
if command_line_arguments[:l]
  puts adjust_line_content_alignment(each_content_count)
else
  puts adjust_content_alignment(each_content_count)
end
