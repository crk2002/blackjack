require 'rubygems'
require 'sinatra'

set :sessions, true

before do
  if session[:game]
    @cash=session[:game].user.cash
    @bet=session[:game].user.bet
    @player_name=session[:game].user.name
  end
  @message={}
end

get '/' do
  session[:game]=Game.new
  session[:game_over]=false
  erb :index
end

post '/new_player' do
  if params[:player_name] =~ /^\s*$/
    @message = {text: "You need to enter a name.", type: "error"}
    halt erb :index
  end
  session[:game].user.name=params[:player_name]
  redirect '/bet'
end

get '/bet' do
  erb :bet
end

post '/bet' do
  session[:game].user.bet=params[:bet].to_i
  if session[:game].user.bet > session[:game].user.cash
    @message = {text: "You bet more than you have!", type: "error"}
    halt erb :bet
  elsif session[:game].user.bet == 0
    @message = {text: "Invalid bet", type: "error"}
    halt erb :bet
  end
  session[:game].deal_flop
  redirect '/game'
end

get '/game' do
 if session[:game_over]
   erb :winner
 else
    @flop=true
    erb :game
  end
end

post '/hit_user' do
  session[:game].hit_user
  if session[:game].winner?
    session[:game].adjust_balance
    redirect "/winner"
  else
    @flop=true
    erb :game, layout: false
  end
end

post '/user_stays' do
  session[:game].hit_computer
  session[:game].adjust_balance
  redirect '/winner'
end

get '/winner' do
  @flop=false
  session[:game_over]=true
  @message=session[:game].announce_winner
  erb :winner, layout: false
end

post '/play_again' do
  session[:game_over]=false
  session[:game].deck=Deck.new
  session[:game].user.cards=[]
  session[:game].computer.cards=[]
  session[:game].user.bet=0
  erb :bet
end

helpers do
  class Deck
    Suits = ["Clubs", "Hearts", "Spades","Diamonds"]
    Faces = ["Jack", "Queen", "King"]
    
    attr_accessor :cards
    
    def initialize
      @cards = []
      Suits.each do |suit|
        (2..9).each {|number| @cards << Card.new(suit, number.to_s, number)}
        Faces.each { |face| @cards << Card.new(suit, face, 10)}
        @cards << Card.new(suit, 'Ace', 11)
      end
      @cards.shuffle!
    end
  end
  
  class Card
    attr_accessor :suit, :face, :value
    
    def initialize(suit, face, value)
      @suit = suit
      @face = face
      @value = value
    end
  
    def to_s
      "#{face} of #{suit}"
    end
    
    def to_img
      "<img src='images/cards/#{suit.downcase}_#{face.downcase}.jpg' alt='#{to_s}'> "
    end
  end
  
  class Player
    attr_accessor :cards
    
    def initialize
      @cards = []
    end
    
    def total
      total=0
      cards.each {|card| total+=card.value}
      while total > 21 && has_elevens?
        devalue_an_eleven
      end
      total
    end
    
    def has_elevens?
      cards.select {|card| card.value == 11}.size > 0
    end
    
    def devalue_an_eleven
      cards.select {|card| card.value == 11}.first.value = 1
    end
    
    def bust?
      total > 21
    end
    
    def blackjack?
      total == 21
    end
    
  end
  
  class Computer < Player
  end
  
  
  class User < Player
    attr_accessor :name, :cash, :bet
    def initialize
      @cash=500
      @bet=0
      super
    end
    
    def wins_cash
      @cash += bet
    end
    
    def loses_cash
      @cash -= bet
    end
    
  end
  
  class Game
    attr_accessor :deck, :user, :computer
    def initialize
      @deck=Deck.new
      @user=User.new
      @computer=Computer.new
    end
    
    def deal_flop
      deal(user,1)
      deal(computer,1)
      deal(user,1)
      deal(computer,1)
    end
    
    def deal(player, number_of_cards)
      number_of_cards.times {player.cards << deck.cards.pop}
    end
    
    def winner?
      if user.blackjack? || user.bust? || computer.blackjack? || computer.bust?
        true
      else
        false
      end
    end
    
    def adjust_balance
      if user.blackjack? || computer.bust?
        user.wins_cash
      elsif user.bust? || computer.blackjack?
        user.loses_cash
      elsif user.total > computer.total
        user.wins_cash
      elsif computer.total > user.total
        user.loses_cash
      end
    end

    def announce_winner
      say_total=" You now have $#{user.cash}."
      if user.blackjack?
        message = {text: "You got blackjack! You won $#{user.bet}!" + say_total, type: "success"}
      elsif user.bust?
        message = {text: "You busted at #{user.total}! You lost $#{user.bet}!" + say_total, type: "error"}
      elsif computer.blackjack?
        message = {text: "The computer got blackjack! You lost $#{user.bet}!" + say_total, type: "error"}
      elsif computer.bust?
        message = {text: "The computer busted at #{computer.total}! You won $#{user.bet}!" + say_total, type: "success"}
      elsif computer.total > user.total
        message = {text: "The computer won! You lost $#{user.bet}!" + say_total, type: "error"}
      elsif user.total > computer.total
        message = {text: "You won $#{user.bet}!" + say_total, type: "success"}
      else
        message = {text: "It's a tie!", type: "warning"}
      end
    end
    
    def new_total
      " You now have $#{user.cash}."
    end
    
    def show_hands(final=false)
      user.hand
      computer.hand(final)
    end
    
    def hit_user
      deal(user,1)
    end
    
    def hit_computer
      until computer.total>=17 || winner?
        deal(computer,1)
      end
    end
  end
end