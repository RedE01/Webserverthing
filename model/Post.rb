require_relative("Db.rb")
require_relative("Model.rb")

class CommentNode
    attr_reader :post, :children

    def initialize(post)
        @post = post
        @children = []
    end

    def addChild(commen_node)
        @children << commen_node
    end
end

class Post < Model

    attr_reader :id, :user_id, :title, :content, :image_name, :parent_post_id, :base_post_id, :depth, :user_name, :base_post_title, :date

    def initialize(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, user_name, base_post_title, date)
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
        @date = date
    end

    def self.find_by(id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil, follower_id: nil)
        queryString = "SELECT posts.*, users.name, basePost.title AS basePostTitle 
            FROM posts INNER JOIN users ON posts.user_id = users.id
            LEFT JOIN posts AS basePost ON posts.base_post_id = basePost.id"

        if(follower_id != nil)
            queryString += " INNER JOIN follows ON posts.user_id = follows.followee_id"
        end

        return find_impl(queryString, id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, order, follower_id)
    end

    def self.insert(user_id, title, content, image_name, parent_post_id, base_post_id, depth)
        db = Db.get()

		db.execute("INSERT INTO posts (user_id, title, content, image_name, parent_post_id, base_post_id, depth, date) VALUES (?, ?, ?, ?, ?, ?, ?, ?);", user_id, title, content, image_name, parent_post_id, base_post_id, depth, Time.now().to_i())
    end

    private
    def self.find_impl(queryStr, id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, order, follower_id)
        search_strings = getSearchStrings(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, follower_id)
        
        queryString = queryStr
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)

        return makeObjectArray(queryString)
    end

    def self.getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth, follower_id)
        search_strings = []

        Post.addStringToQuery("posts.id", id, search_strings)
        Post.addStringToQuery("posts.user_id", user_id, search_strings)
        Post.addStringToQuery("posts.title", title, search_strings)
        Post.addStringToQuery("posts.content", content, search_strings)
        Post.addStringToQuery("posts.image_name", image_id, search_strings)
        Post.addStringToQuery("posts.parent_post_id", parent_post_id, search_strings)
        Post.addStringToQuery("posts.base_post_id", base_post_id, search_strings)
        Post.addStringToQuery("posts.depth", depth, search_strings)
        Post.addStringToQuery("follows.follower_id", follower_id, search_strings)

        return search_strings
    end

    def self.makeObjectArray(queryString)
        db = Db.get()

        posts_db = db.execute(queryString)

        return_array = []
        
        posts_db.each do |data|
            creationDate = Time.at(data['date'].to_i()).to_datetime()
            return_array << Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_name'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'], data['basePostTitle'], creationDate)
        end

        return return_array
    end

end