require_relative("Db.rb")
require_relative("Model.rb")
require_relative("Rating.rb")

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

    attr_reader :id, :user_id, :title, :content, :image_name, :parent_post_id, :base_post_id, :depth, :user_name, :base_post_title, :date, :rating, :current_user_rating, :exist
    attr_writer :title, :content, :image_name

    def initialize(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, user_name, base_post_title, date, rating, current_user_rating, exist)
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
        @rating = rating
        @current_user_rating = current_user_rating
        @exist = exist

        if(@user_name == nil)
            temp = User.find_by(id: @user_id)
            if(temp)
                @user_name = temp.name
            end
        end

        if(@date == nil)
            @date = Time.now().to_datetime()
        end
    end

    # Public: Saves the Post object to database or updates the values if it already exists
    #
    # Returns nothing
    def save()
        db = Db.get()

        if(id)
            db.execute("UPDATE posts SET user_id = ?, title = ?, content = ?, image_name = ?, parent_post_id = ?, base_post_id = ?, depth = ?, rating = ? WHERE id = ?", @user_id, @title, @content, @image_name, @parent_post_id, @base_post_id, @depth, @rating, @id)
        else
            db.execute("INSERT INTO posts (user_id, title, content, image_name, parent_post_id, base_post_id, depth, date, rating, exist) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1);", @user_id, @title, @content, @image_name, @parent_post_id, @base_post_id, @depth, Time.now().to_i(), @rating)
            @id = Post.find_by(user_id: @user_id, title: @title, content: @content, image_name: @image_name, parent_post_id: @parent_post_id, base_post_id: @base_post_id, depth: @depth, exist: @exist, order: [Pair.new("posts.id", "DESC")]).id
        end
    end

    # Public: Adds number to @rating. It does not however create a Rating object so Rating.create should
    # most of the time be used instead, as it automaically calls this function.
    #
    # rating - The number to add to @rating
    #
    # Returns nothing
    def rate(rating)
        @rating += rating
    end

    # Public: Removes the Post object from database. If the post has child posts it is not destroyed
    # and instead has its title and content changed to [REMOVED]. Any attached immages are destroyed. 
    #
    # Returns nothing
    def destroy()
        db = Db.get()

        if(@image_name != nil)
            filepath = "./public/posts/images/#{@user_id}/#{@image_name}"
            File.delete(filepath) if File.exist?(filepath)
        end

        if(Post.where(parent_post_id: @id, exist: 1).length > 0)
            db.execute("UPDATE posts SET title = '[REMOVED]', content = '[REMOVED]', exist = 0 WHERE id = ?;", @id)
        else
            db.execute("DELETE FROM posts WHERE posts.base_post_id = ?;", @id)
            db.execute("DELETE FROM posts WHERE posts.id = ?;", @id)
            db.execute("DELETE FROM ratings WHERE ratings.post_id = ?;", @id)
        end

    end

    # Public: Gets the base query string used when searching for a Post in the database. If any additional
    # values are wanted they can be added to the query by setting additionalSelect.
    #
    # current_user_id - The id of the user currently logged in.
    # additionalSelect - Used to include additional values in the result of the query. Ignored if not set.
    #
    # Returns the base query string.
    def self.getBaseQueryString(current_user_id, additionalSelect: "")
        if(additionalSelect != "")
            additionalSelect = ", " + additionalSelect
        end

        if(current_user_id == nil)
            current_user_id = -1;
        end

        return "SELECT posts.*, users.name, basePost.title AS basePostTitle, currentUserRatings.rating AS currentUserRating #{additionalSelect}
        FROM posts LEFT JOIN users ON posts.user_id = users.id
        LEFT JOIN posts AS basePost ON posts.base_post_id = basePost.id
        LEFT JOIN ratings AS currentUserRatings ON posts.id = currentUserRatings.post_id AND currentUserRatings.user_id = #{current_user_id}"
    end

    # Public: Find all Post objects that match the arguments, if an argument is nil it is ignored.
    #
    # current_user_id - The id of the user currently logged in.
    # id - The id to search for.
    # user_id - The user_id to search for.
    # title -  The title to search for.
    # content - The content to search for.
    # image_name - The image_name to search for.
    # parent_post_id - The parent_post_id to search for.
    # base_post_id - The base_post_id to search for.
    # depth - The depth to search for.
    # order - Specifies the order of the returned objects. It should be an array of Pair objects where val1 = collumn and val2 = "ASC" or "DESC"
    # follower_id - The follower_id to search for.
    # rating - The rating to search for.
    # exist - Specifies if returned objects should exist or not.
    # limit - Specifiec the maximum number of objects to return.
    #
    # Returns a list of 'Post' objects that match the search arguments.
    def self.where(current_user_id: nil, id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil, follower_id: nil, rating: nil, exist: nil, limit: nil)
        queryString = getBaseQueryString(current_user_id)
        if(follower_id != nil)
            queryString += " INNER JOIN follows ON posts.user_id = follows.followee_id"
        end
        
        search_strings = getSearchStrings(id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, follower_id, rating, exist)
        
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)
        queryString += createLimitString(limit)
        
        return makeObjectArray(queryString)
    end
    
    # Public: Find the first Post objects that match the arguments, if an argument is nil it is ignored.
    #
    # current_user_id - The id of the user currently logged in.
    # id - The id to search for.
    # user_id - The user_id to search for.
    # title -  The title to search for.
    # content - The content to search for.
    # image_name - The image_name to search for.
    # parent_post_id - The parent_post_id to search for.
    # base_post_id - The base_post_id to search for.
    # depth - The depth to search for.
    # order - Specifies the order of the returned objects. It should be an array of Pair objects where val1 = collumn and val2 = "ASC" or "DESC"
    # follower_id - The follower_id to search for.
    # rating - The rating to search for.
    # exist - Specifies if returned objects should exist or not.
    #
    # Returns a 'Post' object that match the search arguments.
    def self.find_by(current_user_id: nil, id: nil, user_id: nil, title: nil, content: nil, image_name: nil, parent_post_id: nil, base_post_id: nil, depth: nil, order: nil, follower_id: nil, rating: nil, exist: nil)
        return where(current_user_id: current_user_id, id: id, user_id: user_id, title: title, content: content, image_name: image_name, parent_post_id: parent_post_id, depth: depth, order: order, follower_id: follower_id, rating: rating, exist: exist, limit: 1)[0]
    end

    # Public: Creates a new Post object and saves it to the database.
    #
    # user_id - The user_id of the creator of the post.
    # title - The title of the post.
    # content - The content of the post.
    # image_name - The name of the post image, if there is one.
    # parent_post_id - The id of the parent post.
    # base_post_id - The id of the base post. (The post highest up in the parent post chain).
    # depth - How far the post is down a post chain.
    #
    # Returns nothing.
    def self.create(user_id, title, content, image_name, parent_post_id, base_post_id, depth)
        db = Db.get()

        post = Post.new(nil, user_id, title, content, image_name, parent_post_id, base_post_id, depth, nil, nil, nil, 0, 0, 1)
        post.save()
        return post
    end

    # Public: Creates a new Post object, but don't save it to the database.
    #
    # data - The Hash of data with keys: id, user_id, title, content, image_name, parent_post_id, base_post_id, depth, name, basePostTitle, date, rating, currentUserRating, exist
    #
    # Returns the Post object
    def self.initFromDBData(data)
        return Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_name'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'], data['basePostTitle'], getCreationTime(data['date']), data['rating'], data['currentUserRating'], data['exist'])
    end

    private
    # Internal: Gets a list of sqlite query strings.
    #
    # id - The id to search for.
    # user_id - The user_id to search for.
    # title -  The title to search for.
    # content - The content to search for.
    # image_id - The image id to search for.
    # parent_post_id - The parent_post_id to search for.
    # base_post_id - The base_post_id to search for.
    # depth - The depth to search for.
    # follower_id - The follower_id to search for.
    # rating - The rating to search for.
    # exist - Specifies if returned objects should exist or not.
    #
    # Returns the array of query strings
    def self.getSearchStrings(id, user_id, title, content, image_id, parent_post_id, base_post_id, depth, follower_id, rating, exist)
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
        Post.addStringToQuery("posts.rating", rating, search_strings)
        Post.addStringToQuery("posts.exist", exist, search_strings)

        return search_strings
    end

end