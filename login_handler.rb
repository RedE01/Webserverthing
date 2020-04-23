require_relative 'model/Db.rb'
require_relative 'model/User.rb'

class LoginHandler

    def initialize()

    end

    def self.login(username, password, session)
        user = User.find_by(name: username)
        
        if(user == nil)
            return false
        end
        
        db_hash = BCrypt::Password.new(user.password)
        
        if(db_hash == password)
            session.clear()
			session[:user_id] = user.id
            return true
        end
        
        return false
    end

end