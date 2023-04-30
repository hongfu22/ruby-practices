# frozen_string_literal: true

require 'optparse'
require_relative './file_list'
require_relative './detail_file_list'

options = ARGV.getopts('a', 'l', 'r')
target_path = ARGV.empty? ? './' : ARGV[0]

file =
  if options['l']
    DetailFileList.new(target_path, options)
  else
    FileList.new(target_path, options)
  end

file.produce_file_lists
