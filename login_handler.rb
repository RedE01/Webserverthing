require_relative 'model/Db.rb'
require_relative 'model/User.rb'

class LoginHandler

    def initialize()

    end

    #   Public: Set session[:user_id] to user if username and password match
    #
    #   username - The username of the user that is being logged into
    #   password - The password of the user that is being logged into
    #   session - The session object of the application
    #
    #   Returns true if succesful, false otherwise
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