class User < Sequel:Model
  def initialize user, password, email
    if Users[:user => user].exists? || Users[:email => email].exits?
      return
    else
      encrypted_password= BCrypt::Password.create(password)
      User.create(:username => user,
                  :password => encrypted_password,
                  :email => email
                 )
    end
  end

  def self.authenticate? user, password
    if !Users[:user => user].exists?
  		return redirect to '/login?failed=true'
  	end

  	if !match? user, password
  	  return redirect to '/login?failed=true'
  	else
  	  return session = Users.filter(:username => user).first
  	end
  end

  def match? user password
    return BCrypt::Password.new(Users.filter(:username => user)[:password]) == password

  end

end
