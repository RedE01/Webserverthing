require_relative 'model/Db.rb'
require_relative 'model/User.rb'

# Handles login, login cooldown, and storing login attempts into a separate database
class LoginHandler

    def initialize()

    end

    # Public: Set session[:user_id] to user if username and password match. Sleep for 0.5 seconds for every
    # login attempt by current ip address in the last 60 seconds.
    #
    # username - The username of the user that is being logged into.
    # password - The password of the user that is being logged into.
    # session - The session object of the application.
    #
    # Returns true if succesful, false otherwise.
    def self.login(username, password, session, ip)
        loginLogDb = SQLite3::Database.new('db/login_log.db')

        timeNow = Time.now().to_i()
        recentLogins = loginLogDb.execute("SELECT date FROM login_attempts WHERE ip = ? AND date > ?;", ip, timeNow - 60)
        sleep(recentLogins.count() * 0.5)
        
        user = User.find_by(name: username)
        user_id = -1
        if(user != nil)
            user_id = user.id
        end
        loginLogDb.execute("INSERT INTO login_attempts(ip, user_id, date) VALUES(?,?,?);", ip, user_id, timeNow)
        
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