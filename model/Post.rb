require_relative("Db.rb")
require_relative("Model.rb")

class Post < Model

    attr_reader :id, :user_id, :title, :content, :image_id, :parent_post_id, :base_post_id, :depth, :user_name

    def initialize(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth, user_name)
        @id = id
        @user_id = user_id
        @title = title
        @content = content
        @image_id = image_id
        @parent_post_id = parent_post_id
        @base_post_id = base_post_id
        @depth = depth
        @user_name = user_name
    end

    def self.find_by(id: nil, user_id: nil, title: nil, content: nil, image_id: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil)
        search_strings = getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth)
        
        queryString = "SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id"
        queryString += createSearchString(search_strings)
        queryString += createOrderString("posts.id", order)

        return makeObjectArray(queryString)
    end

    def self.insert(name, password)
        db = Db.get()

        hashedPassword = BCrypt::Password.create('password')
		db.execute("INSERT INTO users(name, password) VALUES (?, ?);", name, hashedPassword)
    end

    private 
    def self.getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth)
        search_strings = []

        User.addStringToQuery("posts.id", id, search_strings)
        User.addStringToQuery("posts.user_id", user_id, search_strings)
        User.addStringToQuery("posts.title", title, search_strings)
        User.addStringToQuery("posts.content", content, search_strings)
        User.addStringToQuery("posts.image_id", image_id, search_strings)
        User.addStringToQuery("posts.parent_post_id", parent_post_id, search_strings)
        User.addStringToQuery("posts.base_post_id", base_post_id, search_strings)
        User.addStringToQuery("posts.depth", depth, search_strings)

        return search_strings
    end

    def self.makeObjectArray(queryString)
        db = Db.get()

        posts_db = db.execute(queryString)

        return_array = []

        posts_db.each do |data|
            return_array << Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_id'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'])
        end

        return return_array
    end

end