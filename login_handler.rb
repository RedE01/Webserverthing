require_relative 'model/Db.rb'
require_relative 'model/User.rb'

class LoginHandler

    def initialize()

    end

    def self.login(username, password)
        user = User.find_by(name: username)
        
        if(user == nil)
            return nil
        end
        
        db_hash = BCrypt::Password.new(user.password)
        
        if(db_hash == password)
            return user
        end
        
        return nil
    end

end