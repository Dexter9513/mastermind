# frozen_string_literal: true

module Symbols
  CIRCLE_SOLID = "\u25cf"
  CIRCLE_HOLLOW = "\u25cb"
  BOX_TOP_LEFT = "\u250c"
  BOX_TOP_RIGHT = "\u2510"
  BOX_BOTTOM_LEFT = "\u2514"
  BOX_BOTTOM_RIGHT = "\u2518"
  BOX_VERTICAL = "\u2502"
  BOX_HORIZONTAL = "\u2500"
  BOX_T_DOWN = "\u252c"
  BOX_T_LEFT = "\u251c"
  BOX_T_RIGHT = "\u2524"
  BOX_T_UP = "\u2534"
  BOX_PLUS = "\u253c"
end

class Peg
  @@selected_peg = nil
  include Symbols

  def initialize(color = nil)
    @color = color
    @symbol = color ? CIRCLE_SOLID : CIRCLE_HOLLOW
  end

  def fill(color)
    @color = color
    @symbol = CIRCLE_SOLID
  end

  def display
    style = if @@selected_peg == self
              5 # blink
            else
              0 # default
            end
    case @color
    when 'red'
      "\e[#{style};31m#{@symbol}\e[m"
    when 'green'
      "\e[#{style};32m#{@symbol}\e[m"
    when 'yellow'
      "\e[#{style};33m#{@symbol}\e[m"
    when 'blue'
      "\e[#{style};34m#{@symbol}\e[m"
    when 'purple'
      "\e[#{style};35m#{@symbol}\e[m"
    when 'cyan'
      "\e[#{style};36m#{@symbol}\e[m"
    else
      "\e[#{style}m#{@symbol}\e[m"
    end
  end
end

class Guess
  attr_reader :guess, :feedback

  def initialize
    @guess = Array.new(4) { Peg.new }
    @feedback = Array.new(4) { Peg.new }
  end
end

class Board
  include Symbols
  def initialize
    @guesses = Array.new(12) { Guess.new }
    @code = Array.new(4) { Peg.new(%w[red blue green cyan yellow purple].sample) }
  end

  def draw_box_top
    print BOX_TOP_LEFT + BOX_HORIZONTAL * 12 + BOX_T_DOWN + BOX_HORIZONTAL * 6 + BOX_TOP_RIGHT
    print "\n"
  end

  def draw_box_bottom
    print BOX_BOTTOM_LEFT + BOX_HORIZONTAL * 12 + BOX_T_UP + BOX_HORIZONTAL * 6 + BOX_BOTTOM_RIGHT
    print "\n"
  end

  def draw_box_middle
    print BOX_T_LEFT + BOX_HORIZONTAL * 12 + BOX_PLUS + BOX_HORIZONTAL * 6 + BOX_T_RIGHT
    print "\n"
  end

  def draw
    draw_box_top
    @guesses.each do |guess|
      print BOX_VERTICAL
      guess.guess.each do |peg|
        print " #{peg.display} "
      end
      print "#{BOX_VERTICAL} "
      guess.feedback.each do |peg|
        print peg.display
      end
      print " #{BOX_VERTICAL}\n"
    end
    draw_box_middle

    print BOX_VERTICAL
    @code.each do |peg|
      print " #{peg.display} "
    end
    print "#{BOX_VERTICAL}      #{BOX_VERTICAL}\n"
    draw_box_bottom
  end
end

class MasterMind
  def initialize
    @board = Board.new
  end

  def start
    @board.draw
  end
end

game = MasterMind.new
game.start
