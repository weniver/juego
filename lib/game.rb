class Game < Sequel::Model
  many_to_one :user
  one_to_many :partys

  def initialize user_id, qty
    if (qty == 1) then vs_comp = 'yes' else vs_comp = 'no' end

    Game.create(:user_id => user_id,
                :winner => 'none' ,
                :state => 'incomplete',
                :turn => 0,
                :vscomp => vs_comp
    )
  end
end
