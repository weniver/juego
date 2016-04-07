class Party < Sequel::Model
  require './lib/warrior.rb'
  many_to_one :game

  def initialize num_players, player_choice #player_choice es un hash id =>[]
    party = {}
    player_choice.each do |id,players|
      party_array << players.map { |player|
    		Warrior.send(warrior.to_sym)
      party[id] = party_array
      party.each do |player_num,warriors|
        warriors.each do |warrior|
          Party.create(
                      :name => warrior.name,
                      :health => warrior.health.to_i,
                      :strength => warrior.strength.to_i,
                      :player => player_num
          )
        end
      end
    end
    if num_players.to_i == 1
      Party.create_computer
    end
  end

  def self.create_computer
    comp_party = []
    5.times do
      comp_party << Warrior.send(['normal','strong','fast'].sample)
    end
    comp_party.each do |warrior|
      Party.create(:name => warrior.name,
                  :health => warrior.health.to_i,
                  :strength => warrior.strength.to_i,
                  :player => 'computer'
                 )
    end
  end

end
