require_relative("Db.rb")
require_relative("Model.rb")

# Takes care of interactions between the webserver and the database for User objects. The user objects 
# can be logged into, to allow certain actions like creating and rating posts
class User < Model
    attr_reader :id, :name, :password

    def initialize(id, name, password)
        @id = id
        @name = name
        @password = password
    end

    # Public: Saves the User object to database or updates the values if it already exists
    #
    # Returns nothing
    def save()
        db = Db.get()

        if(id)
            db.execute("UPDATE users SET name = ?, password = ? WHERE id = ?", @name, @password, @id)
        else
            db.execute("INSERT INTO users(name, password, date) VALUES (?, ?, ?);", @name, @password, Time.now().to_i())
            @id = User.find_by(name: @name).id
        end
    end

    # Public: Removes the User object from database. All 'Following' entries in the database that have a
    # reference to this user are destroyed.
    #
    # Returns nothing
    def destroy()
        db = Db.get()

        db.execute("DELETE FROM users WHERE users.id = ?;", @id)
    end

    # Public: Find all User objects that match the arguments, if an argument is nil it is ignored.
    #
    # id - The id to search for.
    # name - The name to search for.
    # order - Specifies the order of the returned objects. It should be an array of Pair objects where val1 = collumn and val2 = "ASC" or "DESC"
    # limit - Specifiec the maximum number of objects to return.
    #
    # Returns a list of 'User' objects that match the search arguments.
    def self.where(id: nil, name: nil, order: nil, limit: nil)
        search_strings = getSearchStrings(id, name)
                
        queryString = "SELECT * FROM users"
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    # Public: Find the first User objects that match the arguments, if an argument is nil it is ignored.
    #
    # id - The id to search for.
    # name - The name to search for.
    # order - Specifies the order of the returned objects. It should be an array of Pair objects where val1 = collumn and val2 = "ASC" or "DESC"
    # limit - Specifiec the maximum number of objects to return.
    #
    # Returns the first 'User' object that match the search arguments.
    def self.find_by(id: nil, name: nil)
        return where(id: id, name: name, limit: 1)[0]
    end

    # Public: Creates a new User object and saves it to the database.
    #
    # name - The name.
    # password - The plain text password.
    #
    # Returns nothing.
    def self.create(name, password)
        db = Db.get()

        if(find_by(name: name) != nil)
            return
        end

        hashedPassword = BCrypt::Password.create(password)
        newUser = User.new(nil, name, hashedPassword)
        newUser.save()
    end

    # Public: Creates a new User object, but don't save it to the database.
    #
    # data - The Hash of data with keys: 'id', 'name', 'password'.
    #
    # Returns the User object
    def self.initFromDBData(data)
        return User.new(data['id'], data['name'], data['password'])
    end

    private
    # Internal: Gets a list of sqlite query strings.
    #
    # id - The value of id in the database to be queried for
    # name - The value of name in the database to be queried for
    #
    # Returns the array of query strings
    def self.getSearchStrings(id, name)
        search_strings = []

        User.addStringToQuery("users.id", id, search_strings)
        User.addStringToQuery("users.name", name, search_strings)

        return search_strings
    end
end