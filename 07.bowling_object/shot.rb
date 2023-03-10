# frozen_string_literal: true

class Shot
  attr_reader :score_letter

  def initialize(score_letter)
    @score_letter = score_letter
  end

  def score
    return 10 if score_letter == 'X'

    score_letter.to_i
  end
end
