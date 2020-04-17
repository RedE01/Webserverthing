require_relative("Db.rb")
require_relative("Model.rb")

class User < Model
    attr_reader :id, :name, :password

    def initialize(id, name, password)
        @id = id
        @name = name
        @password = password
    end

    def save()
        db = Db.get()

        if(id)
            db.execute("UPDATE users SET name = ?, password = ? WHERE id = ?", @name, @password, @id)
        else
            db.execute("INSERT INTO users(name, password, date) VALUES (?, ?, ?);", @name, @password, Time.now().to_i())
            @id = User.find_by(name: @name).id
        end
    end

    def destroy()
        db = Db.get()

        db.execute("DELETE FROM users WHERE users.id = ?;", @id)
    end

    def self.where(id: nil, name: nil, order: nil, limit: nil)
        search_strings = getSearchStrings(id, name)
                
        queryString = "SELECT * FROM users"
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    def self.find_by(id: nil, name: nil)
        return where(id: id, name: name, limit: 1)[0]
    end

    def self.create(name, password)
        db = Db.get()

        if(find_by(name: name) != nil)
            return
        end

        hashedPassword = BCrypt::Password.create(password)
        newUser = User.new(nil, name, hashedPassword)
        newUser.save()
    end

    def self.initFromDBData(data)
        return User.new(data['id'], data['name'], data['password'])
    end

    private 
    def self.getSearchStrings(id, name)
        search_strings = []

        User.addStringToQuery("users.id", id, search_strings)
        User.addStringToQuery("users.name", name, search_strings)

        return search_strings
    end
end