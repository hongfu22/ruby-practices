# frozen_string_literal: true

require './frame'
require './shot'

class Game
  def initialize(shots)
    @frames = create_frames(shots)
  end

  def create_frames(shots)
    shots = insert_zero_after_strike_shot(shots)
    transform_shots_to_frames(shots)
  end

  def transform_shots_to_frames(shots)
    each_frame = []
    shots.each_slice(2).map.with_index do |pair_of_shots, frame_i|
      if frame_i < 9
        each_frame << Frame.new(*pair_of_shots)
      elsif frame_i == 9
        # 18は19投目にあたり最後のフレームの1投目になる。なので19投目から最後の1投で最終フレームを完成させる。
        each_frame << Frame.new(*shots[18..])
      end
    end
    each_frame
  end

  # 最後のフレーム以外(17投球目以前)のXの後に0を挿入
  def insert_zero_after_strike_shot(shots)
    shots.each_with_index do |shot, shot_i|
      shots.insert(shot_i + 1, '0') if shot == 'X' && shot_i <= 17
    end
  end

  def score
    total_score = 0
    @frames.each_with_index do |frame, frame_i|
      next if frame_i == 9

      total_score += frame.score
      if frame.strike?
        total_score += calc_strike_bonus(frame_i + 1)
      elsif frame.spare?
        total_score += calc_spare_bonus(frame_i + 1)
      end
    end

    total_score += @frames[-1].score_last_frame_points
  end

  def calc_strike_bonus(next_frame_index)
    # 次の次のフレームの1投目を足すか判断する処理なので、次が9フレーム目の場合は除外する。
    if @frames[next_frame_index].strike? && next_frame_index < 9
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
