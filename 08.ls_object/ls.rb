# frozen_string_literal: true

require 'optparse'
require_relative './sub_contents'
require_relative './content_info'

options = ARGV.getopts('a', 'l', 'r')
input_target = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  content_info = ContentsInfo.new(input_target, options)
  content_info.show_info
else
  sub_contents = DirSubContents.new(input_target, options)
  sub_contents.show_contents
end
