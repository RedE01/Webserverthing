require 'sqlite3'
require 'bcrypt'

class Seeder

    def self.seed!
        db = connect
        drop_tables(db)
        create_tables(db)
        populate_tables(db)
    end

    def self.connect
        SQLite3::Database.new 'db/db.db'
    end

    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS users;')
        db.execute('DROP TABLE IF EXISTS posts;')
    end

    def self.create_tables(db)

        db.execute <<-SQL
            CREATE TABLE "users" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"  TEXT NOT NULL,
                "password" TEXT NOT NULL
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "posts" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id" INTEGER,
                "title"  TEXT NOT NULL,
                "content" TEXT NOT NULL
            );
        SQL
    end

    def self.populate_tables(db)
        
        users = [
            { name: "user1", password: "password1" },
            { name: "user2", password: "password2" }
        ]

        posts = [
            { user_id: 1, title: "epicly", content: "Hello there is is an epic post if you ask me"},
            { user_id: 0, title: "also epicly", content: "This is also an epic post if you ask me"}
        ]

        users.each do |user|
            hashed = BCrypt::Password.create(user[:password])
            db.execute("INSERT INTO users (name, password) VALUES(?,?)", user[:name], hashed)
        end

        posts.each do |post| 
            db.execute("INSERT INTO posts (user_id, title, content) VALUES(?,?,?)", post[:user_id], post[:title], post[:content])
        end
    end

end

Seeder.seed!