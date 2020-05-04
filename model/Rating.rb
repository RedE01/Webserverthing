require_relative("Db.rb")
require_relative("Model.rb")
require_relative("Post.rb")

# Takes care of interactions between the webserver and the database for Rating objects. The Rating objects
# keep track of a rating made on a post by a user, and what that rating was. The rating can either be 1 or -1
class Rating < Model
    
    attr_reader :user_id, :post
    attr_accessor :rating

    def initialize(user_id, post, rating)
        @user_id = user_id
        @post = post
        @rating = rating
    end
    
    # Public: Returns "+1" if @rating > 0, "-1" otherwise
    def getRatingString()
        if(@rating > 0)
            return "+1"
        end
        return "-1"
    end
    
    # Public: Removes the Rating object from database
    #
    # Returns nothing
    def destroy()
        db = Db.get()
        db.execute("DELETE FROM ratings WHERE post_id = ? AND user_id = ?", @post.id, @user_id)
    end
    
    # Public: Saves the Rating object to database or updates the values if it already exists
    #
    # Returns nothing
    def save()
        db = Db.get()
        if(Rating.find_by(post_id: @post.id, user_id: @user_id))
            db.execute("UPDATE ratings SET rating = ? WHERE post_id = ? AND user_id = ?;", @rating, @post.id, @user_id)
        else
            db.execute("INSERT INTO ratings VALUES(?,?,?)", @post.id, @user_id, @rating)
        end
    end

    # Public: Find all Rating objects that match the arguments, if an argument is nil it is ignored.
    #
    # current_user_id - The id of the user currently logged in.
    # post_id - The post_id to search for.
    # user_id - The user_id to search for.
    # order - Specifies the order of the returned objects. It should be an array of Pair objects where val1 = collumn and val2 = "ASC" or "DESC"
    # limit - Specifiec the maximum number of objects to return.
    #
    # Returns a list of 'Rating' objects that match the search arguments.
    def self.where(current_user_id: nil, post_id: nil, user_id: nil, order: nil, limit: nil)
        queryString = Post.getBaseQueryString(current_user_id, additionalSelect: "ratings.user_id AS ratings_user_id, ratings.rating AS rating_rating")
        queryString += " INNER JOIN ratings ON posts.id = ratings.post_id"
        
        search_strings = getSearchStrings(post_id, user_id)
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    # Public: Find the first Rating objects that match the arguments, if an argument is nil it is ignored.
    #
    # post_id - The post_id to search for.
    # user_id - The user_id to search for.
    #
    # Returns the first 'Rating' objects that match the search arguments.
    def self.find_by(post_id: nil, user_id: nil)
        return where(post_id: post_id, user_id: user_id, limit: 1)[0]
    end

    # Public: Creates a new Rating object and saves it to the database. It also increments or decrements
    # the rating of the target post accordingly.
    #
    # post_id - The post_id.
    # user_id - The user_id.
    # rating - The rating.
    #
    # Returns nothing.
    def self.create(post_id, user_id, rating)
        db = Db.get()

        rating = rating.to_i()

        if(rating > 0)
            rating = 1
        elsif(rating < 0)
            rating = -1
        end
        
        existingRating = Rating.find_by(post_id: post_id, user_id: user_id)
        deltaRating = rating
        if(existingRating)
            deltaRating = rating - existingRating.rating
        else
            existingRating = Rating.new(user_id, Post.find_by(id: post_id), 0)
        end
        existingRating.rating = rating
        existingRating.save()

        if(deltaRating != 0)
            existingRating.post.rate(deltaRating.to_i())
            existingRating.post.save()
        end

        return existingRating
    end

    # Public: Creates a new Rating object, but don't save it to the database.
    #
    # data - The Hash of data with keys: 'ratings_user_id', 'ratings_rating'.
    #
    # Returns the Rating object
    def self.initFromDBData(data)
        newPost = Post.initFromDBData(data)
        return Rating.new(data['ratings_user_id'], newPost, data['rating_rating'])
    end

    private

    # Internal: Gets a list of sqlite query strings.
    #
    # post_id - The value of post_id in the database to be queried for
    # user_id - The value of user_id in the database to be queried for
    #
    # Returns the array of query strings
    def self.getSearchStrings(post_id, user_id)
        search_strings = []

        Rating.addStringToQuery("ratings.post_id", post_id, search_strings)
        Rating.addStringToQuery("ratings.user_id", user_id, search_strings)

        return search_strings
    end
end