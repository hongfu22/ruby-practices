# frozen_string_literal: true

require 'optparse'
require_relative './dir_content'
require_relative './dir_info'

options = ARGV.getopts('a', 'l', 'r')
dir_path = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  dir_info = InfoList.new(dir_path, options)
  dir_info.produce_info_
else
  dir_contents = DirContent.new(dir_path, options)
  dir_contents.produce_dir_contents
end
