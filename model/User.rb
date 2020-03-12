require_relative("Db.rb")
require_relative("Model.rb")

class User < Model

    attr_reader :id, :name, :password

    def initialize(id, name, password)
        @id = id
        @name = name
        @password = password
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
		db.execute("INSERT INTO users(name, password) VALUES (?, ?);", name, hashedPassword)
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