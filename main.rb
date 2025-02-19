# frozen_string_literal: true

require 'io/console'

module Colors
  RED = 'red'
  GREEN = 'green'
  BLUE = 'blue'
  YELLOW = 'yellow'
  CYAN = 'cyan'
  PURPLE = 'purple'
  ALL_COLORS = { 'r' => RED,
                 'g' => GREEN,
                 'b' => BLUE,
                 'y' => YELLOW,
                 'c' => CYAN,
                 'p' => PURPLE }.freeze
end

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
  include Symbols
  include Colors

  @@selected_peg = nil
  attr_accessor :hidden
  attr_reader :name, :color

  def self.selected_peg
    @@selected_peg
  end

  def self.selected_peg=(peg)
    @@selected_peg = peg
  end

  def initialize(name = nil)
    @color = nil
    @symbol = CIRCLE_HOLLOW
    @hidden = false
    @name = name
  end

  def fill(color)
    @color = color
    @symbol = CIRCLE_SOLID
  end

  def full?
    @symbol == CIRCLE_SOLID
  end

  def display
    style = if @@selected_peg == self
              5 # blink
            elsif hidden
              8 # hidden
            else
              0 # default
            end
    case @color
    when RED
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

  def initialize(block_number)
    @guess = []
    @feedback = []
    1.upto(4) { |index| @guess.push(Peg.new("Guess##{block_number} Peg##{index}")) }
    @feedback = Array.new(4) { Peg.new }
  end
end

class Board
  include Symbols
  attr_reader :guesses, :code

  def initialize
    @guesses = []
    @code = []
    1.upto(12) { |index| @guesses.push(Guess.new(index)) }
    1.upto(4) { |index| @code.push(Peg.new("Code Peg##{index}")) }
  end

  def help
    puts "M A S T E R M I N D
    Inputs:
      ← →: navigate    <Enter>: confirm    <spacebar>: quit
      r: red    g: green    b: blue
      c: cyan   p: purple   y: yellow
    Feedback:
      \e[31m#{CIRCLE_SOLID}\e[m: Color and Position both match
      #{CIRCLE_SOLID}: Color match but not Position"
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
    system('clear')
    help
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
  include Colors
  include Symbols

  def initialize
    @board = Board.new
    set_game_mode
  end

  def set_game_mode
    loop do
      puts 'What do you want to be:'
      puts '1. Code Breaker'
      puts '2. Code Setter'
      print '>> '
      case gets.chomp
      when '1'
        @gamemode = 'code-breaker'
        break
      when '2'
        @gamemode = 'code-setter'
        break
      else
        puts 'Invalid choice!'
      end
    end
  end

  def next_peg
    current_index = @current_block.index(Peg.selected_peg)
    Peg.selected_peg = @current_block.fetch(current_index + 1, @current_block.last)
  end

  def previous_peg
    current_index = @current_block.index(Peg.selected_peg)
    Peg.selected_peg = @current_block.fetch(current_index - 1, @current_block.first)
  end

  def quit
    puts
    Peg.selected_peg = nil
    @board.draw
    exit
  end

  def color_from_stdin
    loop do
      input = $stdin.getch.downcase
      return ALL_COLORS[input] if ALL_COLORS.include?(input)

      case input
      when ' ' then quit
      when "\r"
        return 'confirm' if block_full?

        puts "\nPlease fill all pegs!"
      when '['
        case $stdin.getch
        when 'D' then return 'left'
        when 'C' then return 'right'
        end
      else
        print "\nInvalid Color! Enter again>>"
      end
    end
  end

  def block_full?
    @current_block.each { |peg| return false unless peg.full? }
    true
  end

  def fill_block
    Peg.selected_peg = @current_block[0]
    loop do
      @board.draw

      print "Enter color for #{Peg.selected_peg.name}>> "
      input = color_from_stdin
      case input
      when 'left' then previous_peg
      when 'right' then next_peg
      when 'confirm'
        break if block_full?
      else
        Peg.selected_peg.fill(input)
        next_peg
      end
    end
  end

  def fill_block_auto(pegs)
    Peg.selected_peg = @current_block[0]
    pegs.each do |color|
      @board.draw
      sleep(0.2)
      Peg.selected_peg.fill(color)
      next_peg
    end
  end

  def calculate_feedback(pegs)
    code = @board.code.map(&:color)
    guess = @current_block.map(&:color)

    red_count = 0
    white_count = 0

    guess.each_with_index do |guess_color, guess_index|
      if guess_color == code[guess_index]
        red_count += 1
        code[guess_index] = nil
      else
        code.each_with_index do |code_color, code_index|
          next unless guess_color == code_color && code_color != guess[code_index]

          white_count += 1
          code[code_index] = nil
          break
        end
      end
    end

    to_return = [red_count, white_count]

    pegs.each do |peg|
      if red_count.positive?
        red_count -= 1
        peg.fill(RED)
      elsif white_count.positive?
        white_count -= 1
        peg.fill('white')
      end
    end
    pegs.shuffle!
    to_return
  end

  def check_endgame(pegs)
    pegs.all? { |peg| peg.color == RED }
  end

  def code_setter_mode
    @current_block = @board.code
    fill_block

    guesser = CodeGuesser.new

    @board.guesses.each do |block|
      @current_block = block.guess
      fill_block_auto(guesser.guess)
      feedback = calculate_feedback(block.feedback)
      sleep(0.2)
      if feedback[0] == 4
        @result = 'SORRY, YOUR CODE WAS BROKEN!'
        break
      end
      guesser.evaluate_feedback(feedback)
    end
    @result ||= 'CONGRATULATIONS, YOU CODE WASN\'T BROKEN!'
  end

  def code_breaker_mode
    set_random_code
    hide_code
    @board.guesses.each do |block|
      @current_block = block.guess
      fill_block
      calculate_feedback(block.feedback)
      if check_endgame(block.feedback)
        @result = 'CONGRATULATIONS, YOU BROKE THE CODE!'
        break
      end
    end
    @result ||= 'SORRY, YOU FAILED TO BREAK THE CODE!'
    unhide_code
  end

  def set_random_code
    @board.code.each do |peg|
      random_color = ALL_COLORS.values.sample
      peg.fill(random_color)
    end
  end

  def hide_code
    @board.code.each { |peg| peg.hidden = true }
  end

  def unhide_code
    @board.code.each { |peg| peg.hidden = false }
  end

  def start
    if @gamemode == 'code-setter'
      code_setter_mode
    else
      code_breaker_mode
    end
    Peg.selected_peg = nil
    @board.draw
    puts @result
  end
end

class CodeGuesser
  include Colors

  def initialize
    @colors = ALL_COLORS.values.shuffle
    @tracker = {}
    @voids = []
    @fixed = [nil, nil, nil, nil]
    @choice = nil
  end

  def next_color
    if @choice
      return @colors[@colors.index(@choice) + 1] if @voids.empty?

      @tracker.each do |key, value|
        fixed_positions = @fixed.count(key)
        possible_possitions = value[:positions].length
        return key if possible_possitions > fixed_positions
      end

      loop do
        @choice = @colors[@colors.index(@choice) + 1]
        return @choice unless @voids.include?(@choice)
      end
    else
      @colors[0]
    end
  end

  def next_guess
    @trial_positions = []
    guess = @fixed.dup
    if @tracker.include?(@choice)
      @tracker[@choice][:positions].each do |position|
        next unless @fixed[position].nil?

        guess[position] = @choice
        @trial_positions.push(position)
        break
      end
      guess.map { |color| color.nil? ? @voids.sample : color }
    else
      guess.each_with_index do |color, index|
        next unless color.nil?

        guess[index] = @choice
        @trial_positions.push(index)
      end
      guess
    end
  end

  def guess
    @choice = next_color
    next_guess
  end

  def clean_tracker(position)
    @tracker.each do |key, value|
      value[:positions].delete(position) unless key == @choice
    end
  end

  def evaluate_feedback(feedback)
    match = feedback.sum
    new_match = match - @fixed.compact.length
    if new_match.positive?
      @tracker[@choice] ||= {}
      color = @tracker[@choice]
      if @trial_positions.size == 1
        if feedback[1] == 1
          color[:positions].delete(@trial_positions[0])
          if color[:count] == color[:positions].size
            color[:positions].each do |position|
              @fixed[position] = @choice
              clean_tracker(position)
            end
          end
        else
          @fixed[@trial_positions[0]] = @choice
          clean_tracker(@trial_positions[0])
          if @fixed.count(@choice) == color[:count]
            color[:positions].select! { |position| position <= @trial_positions[0] }
          end
        end
      else
        color[:count] = new_match
        color[:positions] = @trial_positions
        if new_match == @trial_positions.length && !feedback[1].positive?
          @trial_positions.each do |position|
            @fixed[position] = @choice
            clean_tracker(position)
          end
        end
      end
    else
      @voids.push(@choice)
    end
  end
end

game = MasterMind.new
game.start
