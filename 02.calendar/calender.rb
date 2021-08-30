#!/usr/bin/env ruby
require 'color_echo'
require "date"
require 'optparse'

# コマンドライン引数
options = ARGV.getopts('y:', 'm:')

# 今日の日付
today = Date.today

# 年度設定
year = ""
if options["y"]
    year = options["y"]
else
    year = today.year
end

# 月設定
month = ""
if options["m"]
    month = options["m"]
else
    month = today.month
end

# 曜日
day = ["日", "月", "火", "水", "木", "金", "土"]

# 月初
firstDay = Date.new(year.to_i, month.to_i, 1)
# 月末
lastDay = Date.new(year.to_i, month.to_i, -1)

# 日数カウンター
dayNumCount = 1
# 出力列
rowCount = firstDay.wday
# 初期位置
startPosition = "    " * rowCount

# 本日と同年同月の場合に本日の日付の色を変更する
if today.year == year && today.month == month
    CE.pickup(today.day.to_s, :h_white, :red, :underline)
end

# -------------------
# 処理内容

# 年月出力
8.times { print " " }
puts  "#{month}月 #{year}年"

# 曜日文字列出力
dayOutput = day.join("  ")
puts dayOutput

print startPosition

# 日数出力
while dayNumCount <= lastDay.day do
    print " " if dayNumCount <= 9
    print dayNumCount
    if rowCount == 6
        print "\n"
        rowCount = 0
    else
        print "  "
        rowCount += 1
    end
    dayNumCount += 1
end
print "\n"
