# frozen_string_literal: true

require 'etc'
require 'optparse'
require './file_list'
require './detail_file_list'

options = ARGV.getopts('a', 'l', 'r')
opt = OptionParser.new.parse!(ARGV)
file_path = opt.empty? ? './' : opt[0]
if Dir.exist?(file_path)
  files = options['l'] ? DetailFileList.new(file_path, options) : FileList.new(file_path, options)
  files.produce_file_lists
elsif File.exist?(file_path)
  if options['l']
    file = DetailFileList.new(file_path, options)
    file.produce_file_lists
  else
    puts file_path
  end
else
  puts format('ls.rb: %s: No such file or directory', file_path)
end
