require_relative("Db.rb")
require_relative("Model.rb")

class Post < Model

    attr_reader :id, :user_id, :title, :content, :image_name, :parent_post_id, :base_post_id, :depth, :user_name, :base_post_title

    def initialize(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, user_name, base_post_title)
        @id = id
        @user_id = user_id
        @title = title
        @content = content
        @image_name = image_name
        @parent_post_id = parent_post_id
        @base_post_id = base_post_id
        @depth = depth
        @user_name = user_name
        @base_post_title = base_post_title
    end

    def self.find_by(id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil)
        # queryString = "SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id"
        queryString = "SELECT posts.*, users.name, basePost.title AS basePostTitle 
            FROM posts INNER JOIN users ON posts.user_id = users.id
            LEFT JOIN posts AS basePost ON posts.base_post_id = basePost.id"
        return find_impl(queryString, id: id, user_id: user_id, title: title, content: content, image_name: image_name, parent_post_id: parent_post_id, base_post_id: base_post_id, depth: depth, order: order)
    end

    def self.insert(user_id, title, content, image_name, parent_post_id, base_post_id, depth)
        db = Db.get()

		db.execute("INSERT INTO posts (user_id, title, content, image_name, parent_post_id, base_post_id, depth) VALUES (?, ?, ?, ?, ?, ?, ?);", user_id, title, content, image_name, parent_post_id, base_post_id, depth)
    end

    private
    def self.find_impl(queryStr, id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil)
        search_strings = getSearchStrings(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth)
        
        queryString = queryStr
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)

        return makeObjectArray(queryString)
    end

    def self.getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth)
        search_strings = []

        Post.addStringToQuery("posts.id", id, search_strings)
        Post.addStringToQuery("posts.user_id", user_id, search_strings)
        Post.addStringToQuery("posts.title", title, search_strings)
        Post.addStringToQuery("posts.content", content, search_strings)
        Post.addStringToQuery("posts.image_name", image_id, search_strings)
        Post.addStringToQuery("posts.parent_post_id", parent_post_id, search_strings)
        Post.addStringToQuery("posts.base_post_id", base_post_id, search_strings)
        Post.addStringToQuery("posts.depth", depth, search_strings)

        return search_strings
    end

    def self.makeObjectArray(queryString)
        db = Db.get()

        posts_db = db.execute(queryString)

        return_array = []

        posts_db.each do |data|
            return_array << Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_id'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'], data['basePostTitle'])
        end

        return return_array
    end

end