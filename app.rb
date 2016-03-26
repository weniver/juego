require 'rubygems'
require 'bundler'
Bundler.require

require './lib/warrior.rb'

enable :sessions

get '/' do
	puts params.inspect
	"<a href='/play'>PLAY</a>"
end

get '/play' do
	"<p><a href='/teams/1'>1 Player</a></p>
	 <p><a href='/teams/2'>2 Players</a></p>"
end

get "/teams/:qty" do |qty|
	players = (1..qty.to_i)

	erb(:"team/select", layout: nil, locals: {
			qty: qty,
			players: players
		})
end


post "/play/:qty" do |qty|
	parties = []
	session[:qty] = qty.to_i
	params[:player].each do |id, players|
		parties << players.map { |player|
			Warrior.send(player.to_sym)
		}
	end

	if qty.to_i == 1
		parties[1] = []
		5.times do 
			parties[1] << Warrior.send(['normal','strong','fast'].sample)
		end
	end
	session[:parties] = parties
	redirect to ("/fight/0")	
end


get "/fight/:attacker" do |attacker|
	enemy = attacker.to_i == 0 ? 1 : 0;
	turn = attacker.to_i + 1
	enemigos = session[:parties][enemy].each_with_index.map { |w, index|
			health = w.health
			name = w.name
		%{<input type="radio" name="warrior" value="#{index}" />#{name} Warrior HP: #{health}<br/>}
	}
	
	atacantes = session[:parties][attacker.to_i].each.map { |w|
			health = w.health
			name = w.name
			attack = w.strength
		%{<li>#{name} Warrior: #{health}hp -- #{attack} attack.</li>}
	}

	<<-HTML
	<h1><u>Player #{turn} turn</u></h1>
	<h3>Attacking team order:</h3>
	<ol>
		#{atacantes.join('')}
	</ol>
	<h3>Enemy team:</h3>
	<form method="post" action="/attack/#{attacker}/#{enemy}">
  	#{enemigos.join('')}
  	<button type="submit">Attack!</button>
	</form>
	HTML
end


post "/attack/:attacker/:enemy" do |attacker, enemy|

	atacante =  session[:parties][attacker.to_i].first
	enemigo = session[:parties][enemy.to_i][params[:warrior].to_i]

	atacante.attack(enemigo)
	if enemigo.dead?
		session[:parties][enemy.to_i].delete(enemigo)
	end

	first_to_last = session[:parties][attacker.to_i].shift
	session[:parties][attacker.to_i] << first_to_last

	if session[:parties][enemy.to_i].empty?
		winner = enemy.to_i == 0 ? 2 : 1;
		redirect to "victory/player #{winner}"

	elsif session[:qty] == 1
			comp_attacker = session[:parties][1].first
			comp_victim = session[:parties][0].sample
			comp_attacker.attack(comp_victim)

			first_to_last = session[:parties][1].shift
			session[:parties][1] << first_to_last

			if comp_victim.dead?
				session[:parties][0].delete(comp_victim)
			end

			if session[:parties][0].empty?
				redirect to "victory/computer"
			end
			redirect to "/fight/0"
	end

	redirect to "/fight/#{enemy}"
end


get "/victory/:player" do
	winner = params[:player].capitalize
	"<h1>#{winner} wins!</h1>
	<p><a href='/play'>Rematch?</a></p>"
end
