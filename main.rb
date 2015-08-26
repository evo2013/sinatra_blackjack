require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '2jcuyte9lp'

BLACKJACK_AMOUNT = 21
DEALER_MIN = 17

helpers do
  def calculate_total(cards)
    arr = cards.map { |e| e[1] }

    total = 0
    arr.each do |value|
      if value == "A"
        total += 11
      else
        total += value.to_i == 0 ? 10 : value.to_i
      end
    end

    #correct for Aces
    arr.select{|e| e == "A"}.count.times do
      break if total <= BLACKJACK_AMOUNT
        total -= 10
      end
    total
  end

  def card_image(card) ['H', '3']
    suit = case card[0]
      when 'H' then 'hearts'
      when 'S' then 'spades'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
    end

    value = card[1]
    if ['J', 'Q', 'K', "A"].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src= '/images/cards/#{suit}_#{value}.gif' class = 'class_image' >"
  end
end

get '/demo' do
  erb :demo
end


before do
  @show_hit_or_stay_buttons = true
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty? 
    @error = "Name is required."
    halt erb(:set_name)
  elsif params[:bet].nil? || params[:bet].to_i <= 0 
    @error = "Bet amount is required and must be a number greater than zero."
    halt erb(:set_name)
  else 
    session[:player_name] = params[:player_name]
    session[:bet] = params[:bet].to_i.round
    session[:player_total] = params[:player_total]
    redirect '/game'
  end
end

get '/game' do
  session[:turn] = session[:player_name]
  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  2.times do 
     session[:dealer_cards] << session[:deck].pop
     session[:player_cards] << session[:deck].pop
  end

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total == BLACKJACK_AMOUNT
    @replay = true
    @success = "Congratulations, you just hit Blackjack!"
    @show_hit_or_stay_buttons = false
  elsif dealer_total == BLACKJACK_AMOUNT
    @replay = true
    @error = "Sorry, you lose! Dealer just hit Blackjack."
    @show_hit_or_stay_buttons = false
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
    @replay = true
    @success = "Congratulations, you just hit Blackjack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > BLACKJACK_AMOUNT
    @replay = true
    @error = "Sorry, you just busted at #{player_total}!"
    @show_hit_or_stay_buttons = false
  end


  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has decided to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
    @replay = true
    @error = "Sorry, you lose! Dealer just hit Blackjack."
  elsif dealer_total > BLACKJACK_AMOUNT
    @replay = true
    @success = "Congratulations, you win! Dealer just busted at #{dealer_total}!"
  elsif dealer_total >= DEALER_MIN
    redirect '/game/compare' 
  else
    @show_dealer_hit_button = true
  end

  erb :game
end 

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer' 
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false
  dealer_total = calculate_total(session[:dealer_cards])
  player_total = calculate_total(session[:player_cards])

  if player_total > dealer_total
    @replay = true
    @success = "Congratulations, you win! Your hand is worth #{player_total} and dealer hand is worth #{dealer_total}."
  elsif player_total < dealer_total
    @replay = true
    @error = "Sorry, you lose! Dealer hand is worth #{dealer_total} and your hand is worth #{player_total}."
  else
    @replay = true
    @error = "It's a tie at #{player_total}! No winner."
  end

  erb :game
end

get '/finish' do
  erb :finish
end
