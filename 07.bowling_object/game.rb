# frozen_string_literal: true

require './frame'
require './shot'

class Game
  def initialize(shots)
    # 後の処理で各投球を2つずつに分け1フレームとして扱いたいため、最後のフレーム以外のXの後に0を挿入
    shots = zero_insert(shots)
    # 数字にされた各投球を2つずつ配列にし、二次元配列としてまとめる。
    frames = transform_str_to_int(shots).each_slice(2).to_a
    # 2つずつに分けると10フレーム目が3投していた場合あまりの配列ができてしまうため、10投目の配列と結合する。
    if frames[-1].count == 1
      frames[-2].push(*frames[-1])
      frames.delete_at(-1)
    end
    @game = frames.map do |frame|
      Frame.new(*frame)
    end
  end

  # 後の処理で各投球を2つずつに分け1フレームとして扱いたいため、最後のフレーム以外のXの後に0を挿入
  def zero_insert(frames)
    frames.each_with_index do |each_shot, throw_index|
      frames.insert(throw_index + 1, 0) if each_shot == 'X' && throw_index <= 17
    end
  end

  def transform_str_to_int(frames)
    frames.map do |each_shot|
      each_shot = 10 if each_shot == 'X'
      each_shot.to_i
    end
  end

  def score
    total_score = 0
    @game.each_with_index do |frame, frame_index|
      total_score += frame.score
      if frame.first_shot.score == 10 && frame_index < 9
        total_score += strike(frame_index + 1)
      elsif frame.score == 10 && frame_index < 9
        total_score += spare(frame_index + 1)
      end
    end
    total_score
  end

  def strike(next_frame_index)
    if @game[next_frame_index].first_shot.score == 10 && next_frame_index < 9
      # ストライクした次のフレームがストライクだった場合、さらにその次のフレームの1投目のスコアを足す
      10 + @game[next_frame_index + 1].first_shot.score
    else
      # ラストフレームはサードショットが計算されてしまうため、frame.scoreを使わずにそれぞれの投球のスコアを足す
      @game[next_frame_index].first_shot.score + @game[next_frame_index].second_shot.score
    end
  end

  def spare(next_frame_index)
    @game[next_frame_index].first_shot.score
  end
end
