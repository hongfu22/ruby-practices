# frozen_string_literal: true

require 'optparse'
require_relative './file_list'
require_relative './detail_file_list'

options = ARGV.getopts('a', 'l', 'r')
dir_path = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  dir_content_info = DirContentInfo.new(dir_path, options)
  dir_content_info.produce_dir_info
else
  dir_contents = DirContent.new(dir_path, options)
  dir_contents.produce_dir_contents
end
