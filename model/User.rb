require_relative("Db.rb")

class User

    attr_reader :id, :name, :password

    def initialize(id, name, password)
        @id = id
        @name = name
        @password = password
    end

    def self.find_by(id: nil, name: nil)
        db = Db.get()

        search_id_string = ""
        search_name_string = ""
        if(!id)
            p "no id"
        end
        if(!name)
            p "no name"
        end

        user_db = db.execute("SELECT * FROM users WHERE id = ?", 1)[0]

        if(!user_db)
            return nil
        end

        return User.new(user_db['id'], user_db['name'], user_db['password'])
    end
end