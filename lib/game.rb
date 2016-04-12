class Game < Sequel::Model
  require './lib/party.rb'
  many_to_one :user
  one_to_many :partys

  def initialize user_id, qty
    if (qty == 1) then vs_comp = 'yes' else vs_comp = 'no' end

    Game.create(:user_id => user_id,
                :winner => 'none' ,
                :state => 'active',
                :turn => 0,
                :vscomp => vs_comp
    )
  end

  def self.enemy_and_attacker turn, game_in_session
    #se determina quien es enemy
    if game_in_session[:vscomp] == 'yes'
  		enemy = 'computer'
  	elsif turn.to_i.even? then enemy = '2' else enemy = '1'
  	end
    #se determina quien es attacker
    if enemy == 'computer'
      attacker = '1'
    elsif
      attacker = enemy == '1' ? '2' : '1';
    end
    return enemy, attacker
  end

  def self.party_helper enemy, attacker, game_in_session

  	enemigos = Party.filter(:game_id =>game_in_session[:id]).filter(:player => enemy).each { |w|
  			{
  				name: w[:name],
  				health: w.[:health],
  				index: w[:party_position],
  				dead: w[:dead]
  			}
  	}

  	enemigos.each{ |w|
  			{
  				name: w[:name],
  				health: w.[:health],
  				index: w[:party_position],
  				dead: w[:dead]
  			}
  	}

  	atacantes = Party.filter(:game_id =>game_in_session[:id]).filter(:player => enemy)
  end
end
