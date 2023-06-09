# frozen_string_literal: true

require 'optparse'
require_relative './input_contents'
require_relative './detailed_contents'

options = ARGV.getopts('a', 'l', 'r')
target = ARGV.empty? ? '.' : ARGV[0]

if options['l']
  target_contents = DetailedContents.new(target, options)
  target_contents.produce_target_details
else
  target_contents = InputContents.new(target, options)
  target_contents.produce_input_target
end
