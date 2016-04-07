class Game < Sequel::Model
  many_to_one :user
  one_to_many :partys

  def initialize
    vs_comp = false || true if qty.to_i == 1
    Game.create(:user_id => user_id,
                :winner => 'none' ,
                :state => 'incomplete',
                :turn => 0
                :vscomp => vs_comp
    )
  end
end
