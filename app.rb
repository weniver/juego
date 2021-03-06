require 'rubygems'
require 'bundler'
Bundler.require

require './lib/warrior.rb'
enable :sessions

configure do
	# Leemos o creamos el archivo "db.db" con
	# nuestra base de datos
	db = Sequel.connect("sqlite://db.db")

	# Creamos la tabla `users` si no existe ya
	db.create_table?(:users) do
	  primary_key :id
	  String :username
	  String :password
		String :email
		Integer :total_victories
		Integer :total_losses
		Integer :victories_h
		Integer :losses_h
		Integer :victories_c
		Integer :losses_c
		Integer :unfinished_games
	end


	db.create_table?(:stats) do
		Integer :number_of_users
		Integer :games_users
		Integer :games_guests
		Integer :victories_users
		Integer :victories_guests
		Integer :losses_users
		Integer :losses_guests
		Integer :vs_computer
		Integer :vs_human
		Integer :computer_victories
		Integer :computer_losses
	end

	if db[:stats].empty?
		db[:stats].insert({
			number_of_users: 0,
			games_users: 0,
			games_guests: 0,
			victories_users: 0,
			victories_guests: 0,
			losses_users: 0,
			losses_guests: 0,
			vs_computer: 0,
			vs_human: 0,
			computer_victories: 0,
			computer_losses: 0,
		})
	end

	set :db, db
end

get '/' do
	erb :'home/home'
end

get '/play/as' do
	erb :'play/as'
end

get '/play' do
	if params[:guest]=="true"
		session[:usuario] = 'guest'
	end
	erb :'play/play'
end

get '/login' do
	erb :'login/form', locals: {error: params[:failed]=="true"}
end


post '/login' do
	user = settings.db[:users].filter(:username => params[:usuario]).first
	if user.nil?
		redirect to '/login?failed=true'
	end
	passwords_match = BCrypt::Password.new(user[:password]) == params[:password]
	if !passwords_match
	  redirect to '/login?failed=true'
	else
	  session[:usuario] = user
	  redirect to '/play'
	end
end

get '/signup' do
	erb :'signup/form'
end

post '/signup' do
	encrypted_password = BCrypt::Password.create(params[:password])

	settings.db[:users].insert({
		username: params[:usuario],
		password: encrypted_password,
		email: params[:email],
		total_victories: 0,
		total_losses: 0,
		victories_h: 0,
		losses_h: 0,
		victories_c: 0,
		losses_c: 0,
		unfinished_games: 0
	})

	redirect to '/login'
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
			{
				name: w.name,
				health: w.health,
				index: index
			}
	}

	atacantes = session[:parties][attacker.to_i].each.map { |w|
			{
				name: w.name,
				health: w.health,
				attack: w.strength
			}

	}

	erb(:"attack/menu", locals: {
		enemigos: enemigos,
		atacantes: atacantes,
		turn: turn,
		enemy: enemy,
		attacker: attacker
	})
end

post "/attack/:attacker/:enemy" do |attacker, enemy|
	parties = session[:parties]

	warriors = {
		atacante: parties[attacker.to_i],
		enemigo: parties[enemy.to_i]
	}
	atacante = warriors[:atacante].first
	enemigo = warriors[:enemigo][params[:warrior].to_i]

	atacante.attack(enemigo)

	if enemigo.dead?
		session[:parties][enemy.to_i].delete(enemigo)
	end

	first_to_last = session[:parties][attacker.to_i].shift
	session[:parties][attacker.to_i] << first_to_last

	if parties[enemy.to_i].empty?
		winner = 2 - enemy.to_i
		total_key = :total_victories
		if session[:qty] == 1
			key = :victories_c
		elsif winner == 1#contador de victorias y derrotas
			key = :victories_h
		else
			key = :losses_h
			total_key = :total_losses
		end

		r = session[:usuario][key]
		tr = session[:usuario][total_key]
		r += 1
		tr += 1
		settings.db[:users].filter(:id => session[:usuario][:id]).update(
			key => r,
			total_key => tr
		)
		redirect to "victory/player%20#{winner}"

	elsif session[:qty] == 1
			comp_attacker = session[:parties][1].first
			comp_victim = session[:parties][0].sample
			comp_attacker.attack(comp_victim)

			first_to_last = session[:parties][1].shift
			session[:parties][1] << first_to_last

			if comp_victim.dead?
				session[:parties][0].delete(comp_victim)
			end

			if parties[0].empty?
				l, tl =	session[:usuario][:losses_c], session[:usuario][:total_losses]
				l += 1
				tl += 1
				settings.db[:users].filter(:id => session[:usuario][:id]).update(
					:losses_c => l,
					:total_losses => tl
				)
				redirect to "victory/computer"
			end
			redirect to "/fight/0"
	end

	redirect to "/fight/#{enemy}"
end


get "/victory/:player" do
	winner = params[:player].capitalize

	stats = settings.db[:users].filter(:id => session[:usuario][:id]).first #quitar para el pull

	erb(:'victory/player', locals: {
		winner: winner,
		stats: stats #quitar para el pull
	})
end

get '/stats' do
	data = {
		stats: settings.db[:stats].first
	}

	erb(:"stats/display", locals: data)
end
