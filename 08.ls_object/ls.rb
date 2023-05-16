# frozen_string_literal: true

require 'optparse'
require_relative './dir_sub_contents'
require_relative './contents_info'

options = ARGV.getopts('a', 'l', 'r')
input_target = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  content_info = ContentsInfo.new(input_target, options)
  content_info.produce_target_details
else
  sub_contents = DirSubContents.new(input_target, options)
  sub_contents.produce_within_target
end
