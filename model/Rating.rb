require_relative("Db.rb")
require_relative("Model.rb")
require_relative("Post.rb")

class Rating < Model
    
    attr_reader :user_id, :post, :rating

    def initialize(user_id, post, rating)
        @user_id = user_id
        @post = post
        @rating = rating
    end

    def self.get(user_id)     
        queryString = Post.getBaseQueryString(additionalSelect: "ratings.rating")
        queryString += " INNER JOIN ratings ON posts.id = ratings.post_id"
        queryString += " WHERE ratings.user_id = #{user_id}"

        return makeObjectArray(queryString)
    end

    def getRatingString()
        if(@rating > 0)
            return "+1"
        end
        return "-1"
    end

    private
    def self.makeObjectArray(queryString)
        db = Db.get()

        ratings_db = db.execute(queryString)

        return_array = []
        
        ratings_db.each do |data|
            newPost = Post.new(data['id'], data['user_id'], data['title'], data['content'], data['image_name'], data['parent_post_id'], data['base_post_id'], data['depth'], data['name'], data['basePostTitle'], getCreationTime(data['date']))
            return_array << Rating.new(data['user_id'], newPost, data['rating'])
        end

        return return_array
    end
end