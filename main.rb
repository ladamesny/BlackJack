require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?


use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'Batman05'

BLACKJACK = 21

helpers do
  def calculate_total cards
    total=0
    values = cards.map{|card| card[1]}

    values.each do |value|
      case value
      when 'ace'
        total+=11
      when 'jack' 
        total+=10
      when 'queen' 
        total+=10
      when 'king' 
        total+=10
      else
        total+=value.to_i
      end
    end

    values.select{|value| value == 'ace'}.count.times do
      total-=10 if total > BLACKJACK
    end 
    total
  end

  def display_card card
    path = "<img src='/images/cards/"

    case card[0]
      when 'S'
        path +="spades_"
      when 'C'
        path +="clubs_"
      when 'H'
      path +="hearts_"
      when 'D'
      path +="diamonds_"
    end

    path+=card[1]+".jpg'>"
  end

end

before  do
  @show_hit_or_stay = true
  @dealer_turn = false
  @blackjack = false
  @player_bust = false
  @finish_game = false
end

get '/setname' do
  erb :setname
end

post '/setname' do
  if params[:username].empty?
    @error ="Name is required"
    halt erb(:setname)
  end

  session[:username] = params[:username]
  session[:bank] = 500  
  redirect '/setbet'
end

get '/setbet' do
  bank = session[:bank].to_i
  if  bank < 1
    @endMessage = "Sorry, you ran out of Money. Thanks for playing!"
    halt erb :end_game
  else
    erb :setbet
  end
end

post '/setbet' do
  if params[:bet].to_i > session[:bank].to_i
    @error = "You don't have enough money to make that bet. Try again..."
    halt erb :setbet
  elsif params[:bet].to_i < 0
    @error = "That bet don't even make sense. Try again..."
    halt erb :setbet
  elsif params[:bet] == ""
    @error = "Please make a bet."
    halt erb :setbet
  end
  session[:bet] = params[:bet]
  session[:bank] = session[:bank].to_i - session[:bet].to_i
  redirect '/game'
end

get '/game' do
  suits = ['H', 'D', 'C', 'S']
  values = ['ace','2','3','4','5','6','7','8','9','10', 'jack', 'queen','king']
  session[:deck]=suits.product(values).shuffle!

  session[:userhand]=[]
  session[:computerhand]=[]

  session[:computerhand] << session[:deck].pop
  session[:userhand] << session[:deck].pop
  session[:computerhand] << session[:deck].pop
  session[:userhand] << session[:deck].pop

  @score = calculate_total(session[:userhand])
  @dealerscore = calculate_total(session[:computerhand])

  if @dealerscore == BLACKJACK || @score == BLACKJACK
    @blackjack = true
    redirect '/find_winner'
  else
    erb :game
  end
end

post '/game/player/hit' do
  session[:userhand] << session[:deck].pop
  if calculate_total(session[:userhand]) > BLACKJACK
    @show_hit_or_stay = false
    @player_bust = true
    redirect '/find_winner'
  end
  if calculate_total(session[:userhand]) == BLACKJACK
    @show_hit_or_stay = false
    redirect '/find_winner'
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @message="You stayed!"
  @show_hit_or_stay = false
  @dealer_turn = true
  erb :game
end

get '/game/dealer' do
  @dealer_turn = true
  @finish_game = true
  while calculate_total(session[:computerhand]) < 16 do
    session[:computerhand] << session[:deck].pop
  end

  redirect '/find_winner'
end

get '/find_winner' do
  @score = calculate_total(session[:userhand])
  @dealerscore = calculate_total(session[:computerhand])
  @finish_game = true
  @show_hit_or_stay=false

  if @dealerscore == BLACKJACK
    @endMessage = "<strong style='color:red;font-size:20px;' >Dealer got blackjack...Sorry you lose</strong><br><strong style='color:red;font-size:20px;' >You lost $#{session[:bet]}</strong>"
  elsif @score == BLACKJACK
    @endMessage = "<strong style='color:green;font-size:20px;' >You got BLACKJACK - Congratulations!</strong><br><strong style='color:green;font-size:20px;' >You won $#{session[:bet].to_i*2}</strong>"
    session[:bank] = (session[:bank]+session[:bet].to_i+session[:bet].to_i)
  elsif @dealerscore > BLACKJACK
    @endMessage = "<strong style='color:green;font-size:20px;' >Congratulations! You won! Dealer Busted!</strong><br><strong style='color:green;font-size:20px;' >You won $#{session[:bet].to_i*2}</strong>"
    session[:bank] = (session[:bank]+session[:bet].to_i+session[:bet].to_i)
  elsif @score > BLACKJACK
    @endMessage ="<strong style='color:red;font-size:20px;' >Sorry, you busted. You lose...</strong><br><strong style='color:red;font-size:20px;' >You lost $#{session[:bet]}</strong>"
  elsif @dealerscore == @score
    @endMessage = "<strong style='color:blue;font-size:20px;' >You both tied</strong><br><strong style='color:blue;font-size:20px;' >You won back your $#{session[:bet]}</strong>"
    session[:bank] = (session[:bank]+session[:bet].to_i).to_s 
  elsif @dealerscore > @score
    @endMessage = "<strong style='color:red;font-size:20px;' >Sorry, you lost.</strong><br><strong style='color:red;font-size:20px;' >You lost $#{session[:bet]}</strong>"
  else
    @endMessage = "<strong style='color:green;font-size:20px;' >Congratulations! You win!</strong><br><strong style='color:green;font-size:20px;' >You won $#{session[:bet].to_i*2}</strong>"
    session[:bank] = (session[:bank]+session[:bet].to_i+session[:bet].to_i)
  end
      
      
  erb :game
end

get '/endgame' do
  @endMessage = "Thank you for playing"
  erb :end_game
end

not_found do
  erb :not_found
end