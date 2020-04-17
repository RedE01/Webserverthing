require 'sqlite3'
require 'bcrypt'

class Seeder

    def self.seed!
        db = connect
        db.execute("PRAGMA foreign_keys = ON;")
        drop_tables(db)
        create_tables(db)
        populate_tables(db)
    end

    def self.connect
        SQLite3::Database.new 'db/db.db'
    end

    def self.drop_tables(db)
        db.execute('DROP TABLE IF EXISTS follows;')
        db.execute('DROP TABLE IF EXISTS ratings;')
        db.execute('DROP TABLE IF EXISTS posts;')
        db.execute('DROP TABLE IF EXISTS users;')
    end

    def self.create_tables(db)

        db.execute <<-SQL
            CREATE TABLE "users" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "name"  TEXT NOT NULL,
                "password" TEXT NOT NULL,
                "date" INTEGER NOT NULL
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "posts" (
                "id"    INTEGER PRIMARY KEY AUTOINCREMENT,
                "user_id" INTEGER,
                "title"  TEXT DEFAULT 'default value epic',
                "content" TEXT NOT NULL DEFAULT 'default value also epic',
                "image_name" TEXT,
                "parent_post_id" INTEGER REFERENCES posts(id) ON DELETE SET NULL,
                "base_post_id" INTEGER REFERENCES posts(id) ON DELETE SET NULL,
                "depth" INTEGER NOT NULL,
                "date" INTEGER NOT NULL,
                "rating" INTEGER NOT NULL,
                "exist" INTEGER NOT NULL
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "follows" (
                "follower_id" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "followee_id" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "date" INTEGER NOT NULL
            );
        SQL

        db.execute <<-SQL
            CREATE TABLE "ratings" (
                "post_id" INTEGER NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
                "user_id" INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                "rating" INTEGER NOT NULL
            );
        SQL
    end

    def self.populate_tables(db)
        
        users = [
            { name: "user1", password: "password1" },
            { name: "user2", password: "password2" }
        ]

        posts = [
            { user_id: 1, title: "epicly", content: "Hello there is is an epic post if you ask me", image_name: nil, parent_post_id: nil, base_post_id: nil, depth: 0, exist: 1},
            { user_id: 2, title: "also epicly", content: "This is also an epic post if you ask me", image_name: nil, parent_post_id: nil, base_post_id: nil, depth: 0, exist: 1},
            { user_id: 2, title: nil, content: "This is an epic comment if you ask me", image_name: nil, parent_post_id: 1, base_post_id: 1, depth: 1, exist: 1},
            { user_id: 1, title: nil, content: "This is an awesome comment if you ask me", image_name: nil, parent_post_id: 3, base_post_id: 1, depth: 2, exist: 1},
            { user_id: 2, title: nil, content: "Hello", image_name: nil, parent_post_id: 3, base_post_id: 1, depth: 2, exist: 1}
        ]

        follows = [
            { follower_id: 2, followee_id: 1 }
        ]

        ratings = [
            { post_id: 2, user_id: 1, rating: 1 },
            { post_id: 3, user_id: 1, rating: -1 }
        ]

        users.each do |user|
            hashed = BCrypt::Password.create(user[:password])
            db.execute("INSERT INTO users (name, password, date) VALUES(?,?,?)", user[:name], hashed, Time.now.to_i)
        end

        posts.each do |post| 
            db.execute("INSERT INTO posts (user_id, title, content, image_name, parent_post_id, base_post_id, depth, date, rating, exist) VALUES(?,?,?,?,?,?,?,?,?,?);", post[:user_id], post[:title], post[:content], post[:image_name], post[:parent_post_id], post[:base_post_id], post[:depth], Time.now.to_i, 0, post[:exist])
        end

        follows.each do |follow| 
            db.execute("INSERT INTO follows (follower_id, followee_id, date) VALUES(?, ?, ?);", follow[:follower_id], follow[:followee_id], Time.now.to_i)
        end

        # ratings.each do |rating|
        #     db.execute("INSERT INTO ratings VALUES(?, ?, ?);", rating[:post_id], rating[:user_id], rating[:rating])
        # end
    end

end

Seeder.seed!