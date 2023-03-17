# frozen_string_literal: true

require './frame'
require './shot'

class Game
  def initialize(frames)
    @frames = create_frames(frames)
  end

  def create_frames(frames)
    frames = insert_zero_to_strike_frame(frames)
    frames = divide_into_each_frame(frames)
    frames = combine_third_shot_of_final_frame(frames) if frames[-1].count == 1
    frames.map do |frame|
      Frame.new(*frame)
    end
  end

  # ラストゲームの3投目があった場合に要素1つの配列ができてしまうため、10ゲーム目の2投と結合する
  def combine_third_shot_of_final_frame(frames)
    third_shot = frames.pop
    two_shots = frames.pop
    last_game = two_shots + third_shot
    frames.push(last_game)
  end

  
  def divide_into_each_frame(frames)
    frames.each_slice(2).to_a
  end

  # 最後のフレーム以外(17投球目以前)のXの後に0を挿入
  def insert_zero_to_strike_frame(frames)
    frames.each_with_index do |each_shot, shot_index|
      frames.insert(shot_index + 1, 0) if each_shot == 'X' && shot_index <= 17
    end
  end

  def score
    total_score = 0
    @frames.each_with_index do |frame, frame_index|
      next if frame_index == 9

      total_score += frame.score
      if frame.check_strike_shot?
        total_score += calc_strike_bonus(frame_index + 1)
      elsif frame.check_spare_shots?
        total_score += calc_spare_bonus(frame_index + 1)
      end
    end

    total_score += @frames[-1].score_last_game_points
  end

  def calc_strike_bonus(next_frame_index)
    # 次の次のフレームの1投目を足すか判断する処理なので、次が9フレーム目の場合は除外する。
    if @frames[next_frame_index].check_strike_shot? && next_frame_index < 9
      # ストライクした次のフレームがストライクだった場合、さらにその次のフレームの1投目のスコアを足す
      10 + @frames[next_frame_index + 1].first_shot.score
    else
      @frames[next_frame_index].score
    end
  end

  def calc_spare_bonus(next_frame_index)
    @frames[next_frame_index].first_shot.score
  end
end
