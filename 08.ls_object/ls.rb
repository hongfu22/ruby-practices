# frozen_string_literal: true

require 'optparse'
require_relative './sub_contents'
require_relative './content_info'

options = ARGV.getopts('a', 'l', 'r')
dir_path = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  dir_info = ContentInfo.new(dir_path, options)
  dir_info.produce_content_info
else
  dir_contents = DirContent.new(dir_path, options)
  dir_contents.produce_dir_contents
end
