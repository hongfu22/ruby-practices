# frozen_string_literal: true

require './game'

scores = ARGV[0].split(',')
game = Game.new(scores)
puts game.score
