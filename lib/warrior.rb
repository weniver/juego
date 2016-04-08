class Warrior
	@@basehealth = 1000
	@@basestrength = 300

	attr_accessor :health, :strength, :name
	@@phrases = ['DIE!',
		    			 'TAKE THIS!',
		   				 'Sorry...NOT!',
						   'CHIN CHON LING LONG WANCHINKTON!',
						   'Walk on home boy.'
	]

	def initialize (name, health=@@basehealth, strength=@@basestrength)
		@name = name
		@health = health
		@strength = strength
	end
	#clases de warrior
	def self.normal
		health = @@basehealth + (100 + rand(0..100))
		strength = @@basestrength + (15 + rand(0..15))
		Warrior.new('Normal', health, strength)
	end

	def self.fast #menos vida mas ataque
		health = @@basehealth - (200 + rand(0..200))
		strength = @@basestrength + (30 + rand(0..30))
		Warrior.new('Fast', health, strength)
	end

	def self.strong #menos vida mas ataque
		health = @@basehealth + (200 + rand(0..200))
		strength = @@basestrength - (30 + rand(0..30))
		Warrior.new('Strong', health, strength)
	end

	def attack(enemy)
		bonus = critical
		damage = @strength * bonus
		enemy.health -= damage
		critical_shout = 'Critical Attack!<br>' if bonus == 2
		critical_shout = 'Super Critical Attack!<br>' if bonus == 3
		critical_shout = '' if bonus == 1

		return @@phrases.sample + "<br>#{critical_shout}The attack deals #{damage} damage!"
	end

	def critical
		luck = rand(1..100)
		case luck
		when 1
			3
		when 2..20
			2
		else
			1
		end
	end

	def talk(words)
		puts words
	end

	def dead?
		if self.health <= 0
			return true
		end
	end

end
