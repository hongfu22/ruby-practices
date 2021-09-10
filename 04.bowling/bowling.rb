# !/usr/bin/env ruby
# frozen_string_literal: true

# 入力値受け取り
score = ARGV[0]
# 区切って配列に代入
scores = score.split(',')
# 各投球の数値格納用
shots = []

# 各投球ごとに配列に格納
scores.each do |s|
  if s == 'X'
    shots << 10
    shots << 0
  else
    shots << s.to_i
  end
end

# 2投球ごとに1ゲームでまとめる
frames = []
shots.each_slice(2) do |s|
  frames << s
end

# 最終ゲームが3球の場合の配列を作る
# 最終でストライクが連続で出ると配列が増えすぎるので10組になるまで連結
while frames.size > 10
  tmp = frames.pop(2)
  frames.push(tmp[0] + tmp[1])
end

# 最終ゲームでのストライクにより9ゲーム目でのスペア
# ストライクに影響が出ないようにストライク判定で入れた０を消去
frames.last.each_with_index do |f, i|
  frames.last.delete_at(i + 1) if f == 10 && frames.last[i + 1].zero?
end

# 合計ポイント計算用
point = 0

# 連続ストライクの場合は2ゲーム先の1投目を足す為の関数
# game_index:次ゲームの数字、args:各ゲーム各投球のスコアを入れた配列
def strike_cal(game_index, game_array)
  if game_index < 9 && game_array[game_index][0] == 10
    game_array[game_index][0] + game_array[game_index + 1][0]
  else
    game_array[game_index][0] + game_array[game_index][1]
  end
end

# 合計を計算する処理
frames.each_with_index do |frame, i|
  # 10ゲーム目は足すだけ
  if i == 9
    point += frame.sum
    break
  end

  point +=
    if frame[0] == 10
      10 + strike_cal(i + 1, frames)
    elsif frame.sum == 10
      10 + frames[i + 1][0]
    else
      frame.sum
    end
end
puts point
