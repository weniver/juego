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
		Integer :unfinishe_games
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
	erb :'play/play'
end

get '/login' do
	erb :'login/form', locals: {error: params[:failed]=="true"}
end


post '/login' do
	user = settings.db[:users].filter(:username => params[:usuario]).first
	passwords_match = BCrypt::Password.create(request[:password]) == params[:password]

	if user.nil? || !passwords_match
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
		unfinishe_games: 0
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

	atacante = session[:parties][attacker.to_i].first
	enemigo = session[:parties][enemy.to_i][params[:warrior].to_i]

	atacante.attack(enemigo)
	if enemigo.dead?
		session[:parties][enemy.to_i].delete(enemigo)
	end

	first_to_last = session[:parties][attacker.to_i].shift
	session[:parties][attacker.to_i] << first_to_last

	if session[:parties][enemy.to_i].empty?
		winner = enemy.to_i == 0 ? 2 : 1;
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

			if session[:parties][0].empty?
				redirect to "victory/computer"
			end
			redirect to "/fight/0"
	end

	redirect to "/fight/#{enemy}"
end


get "/victory/:player" do
	winner = params[:player].capitalize
	erb(:'victory/player', locals: {
		winner: winner
	})
end
