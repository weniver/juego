class User < Sequel::Model

  def initialize user, password, email
    if Users[:user => user].exists? || Users[:email => email].exits?
      return redirect to '/signup?error=true'
    else
      encrypted_password= BCrypt::Password.create(password)
      User.create(:username => user,
                  :password => encrypted_password,
                  :email => email
                 )
      return true
    end
  end

  def self.authenticate? user, password
    if !Users[:user => user].exists?
  		return false
  	end

  	if !match? user, password
  	  return false
  	else
  	  return true
  	end
  end

  def match? user, password
    return BCrypt::Password.new(Users.filter(:username => user)[:password]) == password

  end

end
