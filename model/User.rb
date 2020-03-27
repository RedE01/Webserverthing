require_relative("Db.rb")
require_relative("Model.rb")

class User < Model
    @@current_user = nil

    attr_reader :id, :name, :password

    def initialize(id, name, password)
        @id = id
        @name = name
        @password = password
    end

    def self.login(username, password)
        user = find_by(name: username)[0]
		
		if(user == nil)
			return false
		end
		
		db_hash = BCrypt::Password.new(user.password)
		
		if(db_hash == password)
            setCurrentUser(user.id)
			return true
		end
		
		return false
    end

    def self.find_by(id: nil, name: nil)
        search_strings = getSearchStrings(id, name)
                
        queryString = "SELECT * FROM users"
        queryString += createSearchString(search_strings)

        return makeObjectArray(queryString)
    end

    def self.insert(name, password)
        db = Db.get()

        hashedPassword = BCrypt::Password.create(password)
		db.execute("INSERT INTO users(name, password, date) VALUES (?, ?, ?);", name, hashedPassword, Time.now().to_i())
    end

    def self.getCurrentUser()
        return @@current_user
    end

    def self.setCurrentUser(id)
        if(id == nil)
            @@current_user = nil
            return
        end

        @@current_user = User.find_by(id: id)[0]
    end

    private 
    def self.getSearchStrings(id, name)
        search_strings = []

        User.addStringToQuery("users.id", id, search_strings)
        User.addStringToQuery("users.name", name, search_strings)

        return search_strings
    end

    def self.makeObjectArray(queryString)
        db = Db.get()

        user_db = db.execute(queryString)

        return_array = []

        user_db.each do |data|
            return_array << User.new(data['id'], data['name'], data['password'])
        end

        return return_array
    end
end