class User < Sequel::Model
#primero trate de hacerlo con initialize y new pero decia que tenia un numero incorrecto de argumentos
  def self.signup username, password, email
    if !User[:username => username].nil? || !User[:email => email].nil?
      return '/signup?failed=true'
    else
      encrypted_password= BCrypt::Password.create(password)
      User.create(:username => username,
                  :password => encrypted_password,
                  :email => email
                 )
      return '/login?success=true'
    end
  end

  def match? username, password
    return BCrypt::Password.new(User.filter(:username => username)[:password]) == password
  end

  def self.authenticate? username, password
    if !User[:username => username].nil?
  		return false
  	end

  	unless match? (username, password)
  	  return false
  	else
  	  return true
  	end
  end

end
