# frozen_string_literal: true

require 'optparse'
require_relative './sub_contents'
require_relative './content_info'

options = ARGV.getopts('a', 'l', 'r')
dir_path = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  content_info = ContentInfo.new(dir_path, options)
  content_info.produce_content_info
else
  sub_contents = SubContents.new(dir_path, options)
  sub_contents.produce_sub_contents
end
