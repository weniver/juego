require 'rubygems'
require 'bundler'
Bundler.require

configure do
	# Leemos o creamos el archivo "db.db" con
	# nuestra base de datos
	#LO CAMBIE A DB EN MAYUSCULAS POR QUE ASI DICE SEQUEL QUE LO PREFIERE
	DB = Sequel.connect("mysql://root:asdf1234@localhost/juego")

# Creamos la tabla `users` si no existe ya
	DB.create_table?(:users) do
	  primary_key :id
	  String :username, unique: true
	  String :password
		String :email, unique: true
	end

	DB.create_table?(:games) do
		primary_key :id
		foreign_key :user_id, :users
		String :winner #1,2 o computer
		Integer :turn #even or odd
		Boolean :active
		Boolean :vscomp
	end

	DB.create_table?(:partys) do
		primary_key :id
		foreign_key :game_id, :games
		String :name
		Integer :health
		Integer :strength
		Integer :party_position
		String :player #1 or 2 or computer
		String :dead #yes or no
	end
#los juegos tienen dos parties, el turno es para recordar entre sesiones que
#jugador puede atacar
	set :db, DB
end

require './lib/warrior.rb'
require './lib/user.rb'
enable :sessions

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
	erb :'login/form', locals: {
		error: params[:failed]=="true",
		success: params[:success]=="true"
	}
end

post '/login' do
	if User.authenticate? params[:username], params[:password]
		session[:usuario] = User.filter(:username => params[:username]).first
		#Aqui checa si el usuario ya tiene un juego activo, si lo tiene te
		#redirige a donde se quedo el juego anterior.
		last_game = Game.filter(:user_id => session[:usuario][:id]).last
		if last_game[:state] == 'active'
			session[:game] = last_game
			turn = session[:game][:turn]
			redirect to ("/fight/#{turn}")
		end

		redirect to '/play'
	else
		redirect to '/login?failed=true'
	end
end

get '/signup' do
	erb :'signup/form', locals: {error: params[:failed]=="true"}
end

post '/signup' do
	url = User.signup params[:username], params[:password], params[:email]
#checar si ya existe el usuario or email se redirige a /sigup?error=true o login
	redirect to url
end

get "/teams/:qty" do |qty|
	players = (1..qty.to_i)

	erb(:"team/select", layout: nil, locals: {
			qty: qty,
			players: players
		})
end

post "/play/:qty" do |qty|
		user_id = session[:usuario][:id]
		Game.new user_id, qty.to_i
		session[:game] = Game.last
		game_id = session[:game][:id]
		Party.new qty.to_i, params[:player], game_id
		turn = session[:game][:turn]
	end
	redirect to ("/fight/#{turn}")
end


get "/fight/:turn" do |turn|
	enemy, attacker = Game.enemy_and_attacker turn, session[:game]
	enemies, attackers = Game.party_helper enemy, attacker, session[:game]

#<><><>AQUI VOY TODAVIA NO PONGO LO DEL ERB<><><><>
	erb(:"attack/menu", locals: {
		enemies: enemies,
		attackers: attackers,
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

get '/table' do
	todo = User.all.each{|user| p user}
	erb :table, locals: {todo: todo}
end
