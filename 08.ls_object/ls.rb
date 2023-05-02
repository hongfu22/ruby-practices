# frozen_string_literal: true

require 'optparse'
require_relative './file_list'
require_relative './detail_file_list'

options = ARGV.getopts('a', 'l', 'r')
target_path = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  file_list = DetailedlFileInfo.new(target_path, options)
  file_list.produce_info_lists
else
  file_list = FileList.new(target_path, options)
  file_list.produce_file_lists
end
