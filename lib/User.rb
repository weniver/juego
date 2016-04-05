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

  def self.match? username, password
    return BCrypt::Password.new(User.where(:username => username).first[:password]) == password
  end

  def self.authenticate? username, password
    if User[:username => username].nil?
      return false
  	end

  	if User.match? username, password
  	  return true
  	else
  	  return false
      p '2'
  	end
  end

end
