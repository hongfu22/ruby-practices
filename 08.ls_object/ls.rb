# frozen_string_literal: true

require 'optparse'
require_relative './dir_sub_contents'
require_relative './detailed_contents'

options = ARGV.getopts('a', 'l', 'r')
input_target = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  target_details = DetailedContents.new(input_target, options)
  target_details.produce_target_info
else
  target_contents = IncludedContents.new(input_target, options)
  target_contents.produce_within_target
end
