# frozen_string_literal: true

require './shot'

class Frame
  attr_reader :first_shot, :second_shot, :third_shot

  def initialize(first_shot, second_shot, third_shot = nil)
    @first_shot = Shot.new(first_shot)
    @second_shot = Shot.new(second_shot)
    @third_shot = Shot.new(third_shot)
  end

  def score
    [first_shot.score, second_shot.score].sum
  end

  def score_last_game_points
    [first_shot.score, second_shot.score, third_shot.score].sum
  end

  def strike?
    first_shot.score == 10
  end

  def spare?
    score == 10
  end

  def add_last_shot_of_last_game
    third_shot.score
  end
end
