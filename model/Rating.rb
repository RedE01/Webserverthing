require_relative("Db.rb")
require_relative("Model.rb")
require_relative("Post.rb")

class Rating < Model
    
    attr_reader :user_id, :post
    attr_accessor :rating

    def initialize(user_id, post, rating)
        @user_id = user_id
        @post = post
        @rating = rating
    end
    
    def getRatingString()
        if(@rating > 0)
            return "+1"
        end
        return "-1"
    end

    def update()
        db = Db.get()
        db.execute("UPDATE ratings SET rating = ? WHERE post_id = ? AND user_id = ?;", @rating, @post.id, @user_id)
    end

    def delete()
        db = Db.get()
        db.execute("DELETE FROM ratings WHERE post_id = ? AND user_id = ?", @post.id, @user_id)
    end

    def self.where(post_id: nil, user_id: nil, order: nil, limit: nil)
        queryString = Post.getBaseQueryString(additionalSelect: "ratings.user_id AS ratings_user_id, ratings.rating")
        queryString += " INNER JOIN ratings ON posts.id = ratings.post_id"
        
        search_strings = getSearchStrings(post_id, user_id)
        queryString += createSearchString(search_strings)
        queryString += createOrderString(order)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    def self.find_by(post_id: nil, user_id: nil)
        return where(post_id: post_id, user_id: user_id, limit: 1)[0]
    end

    # Should not be used by itself as it does not increate the posts total rating counter
    def self.insert(post_id, user_id, rating) # Returns 1 if rating increased, -1 if rating decreased and 0 if rating stayed static
        db = Db.get()

        rating = rating.to_i()

        if(rating > 0)
            rating = 1
        elsif(rating < 0)
            rating = -1
        end
        
        existingRating = Rating.find_by(post_id: post_id, user_id: user_id)
        if(existingRating != nil)
            if(existingRating.rating == rating)
                return 0
            end

            if(rating == 0)
                existingRating.delete()
                return -existingRating.rating
            end

            existingRating.rating = rating
            existingRating.update()

            return rating * 2
        end

        if(rating != 0)
            db.execute("INSERT INTO ratings VALUES (?, ?, ?);", post_id, user_id, rating.to_i())
        end
        return rating
    end

    def self.initFromDBData(data)
        newPost = Post.initFromDBData(data)
        return Rating.new(data['ratings_user_id'], newPost, data['rating'])
    end

    private
    def self.getSearchStrings(post_id, user_id)
        search_strings = []

        Rating.addStringToQuery("ratings.post_id", post_id, search_strings)
        Rating.addStringToQuery("ratings.user_id", user_id, search_strings)

        return search_strings
    end
end