require 'openssl'
require 'securerandom'

class NonTransitiveGame
  attr_accessor :secret_key, :moves_map

  def initialize(moves)
    if moves.length < 3 || moves.length.even? || moves.uniq.length != moves.length
      raise ArgumentError, 'Incorrect parameters. Please provide an odd number of non-repeating strings.'
    end

    @moves = moves
    @moves_map = {}
    @moves.each_with_index { |move, index| @moves_map[index + 1] = move }
    @secret_key = KeyGenerator.generate_secret_key
  end

  def start_game
    loop do
      @secret_key = KeyGenerator.generate_secret_key 
      computer_move_index = SecureRandom.rand(1..@moves_map.length)
      computer_move = @moves_map[computer_move_index]
      hmac = HMACGenerator.generate_hmac(computer_move, @secret_key)
  
      puts "HMAC: #{hmac}"
      print_menu
  
      user_input = nil
      while user_input.nil? || !valid_move?(user_input.to_i)
        print 'Enter your move (or "0" to exit, "?" for help): '
        user_input = $stdin.gets.chomp
  
        if user_input == '?'
          print_help_table
        elsif user_input == '0'
          puts 'Exiting the game...'
          return 
        elsif valid_move?(user_input.to_i)
          break  
        else
          puts 'Invalid input. Please enter a valid move number.'
        end
      end
  
      user_move_index = user_input.to_i
      user_move = @moves_map[user_move_index]
      result = Rules.determine_winner(user_move, computer_move, @moves_map)
  
      puts "Your move: #{user_move}"
      puts "Computer move: #{computer_move}"
      display_result(result)
      puts "Secret key was used: #{@secret_key}"
    end
  end

  private

  def print_menu
    puts 'Available moves:'
    @moves_map.each { |number, move| puts "#{number} - #{move}" }
    puts '0 - exit'
    puts '? - help'
  end

  def display_result(result)
    case result
    when :win
      puts "You win!"
    when :lose
      puts "You lose!"
    when :draw
      puts "It's a draw!"
    else
      puts "Unexpected result: #{result}"
    end
  end

  def print_help_table
    HelpTableGenerator.new(@moves_map).generate_table
  end

  def valid_move?(input)
    input.is_a?(Integer) && @moves_map.has_key?(input)
  end
end

class KeyGenerator
  def self.generate_secret_key
    OpenSSL::Random.random_bytes(32).unpack1('H*')
  end
end

class HMACGenerator
  def self.generate_hmac(message, key)
    binary_key = [key].pack('H*')
    hmac = OpenSSL::HMAC.new(binary_key, OpenSSL::Digest::SHA256.new)
    hmac.update(message)
    hmac.hexdigest
  end
end

class Rules
  def self.determine_winner(user_move, computer_move, moves_map)
    user_index = moves_map.key(user_move)
    computer_index = moves_map.key(computer_move)
    length = moves_map.length

    if user_index == computer_index
      :draw
    elsif (user_index - computer_index) % length == 1 || user_index == (computer_index + length / 2) % length
      :win
    else
      :lose
    end
  end
end

class HelpTableGenerator
  def initialize(moves_map)
    @moves_map = moves_map
  end

  def generate_table
    puts 'Help Table:'
    print_header_row
    print_divider_row

    @moves_map.each do |number, move|
      print_row(move)
      print_divider_row
    end
  end

  private

  def print_header_row
      return if @moves_map.nil? || @moves_map.empty?
  
      puts '+-------------+' + '--------+' * @moves_map.length
      puts '| v PC\User > |' + @moves_map.map { |number, move| " #{move.to_s.ljust(7)}|" }.join('')
  end
  
    def print_divider_row
      return if @moves_map.nil? || @moves_map.empty?
  
      puts '+-------------+' + '--------+' * @moves_map.length
  end
  
    def print_row(move)
      return if @moves_map.nil? || @moves_map.empty?

      print "| #{move.to_s.ljust(14)} |"
      @moves_map.each do |number, opponent_move|
        result = Rules.determine_winner(move, opponent_move, @moves_map)
        print " #{result.to_s.ljust(5)} |"
      end
      puts
  end
end

begin
  if ARGV.length >= 3
    game = NonTransitiveGame.new(ARGV)
    game.start_game
  else
    puts 'Incorrect parameters. Please provide an odd number of non-repeating strings.'
    puts 'Example: ruby rock.rb rock paper scissors'
end
rescue ArgumentError => e
  puts e.message
end
