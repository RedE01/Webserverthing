require_relative("Db.rb")
require_relative("Model.rb")

class Follow < Model
    attr_reader :follower_id, :followee_id, :date

    def initialize(follower_id, followee_id, date)
        @follower_id = follower_id
        @followee_id = followee_id
        @date = date
    end

    def save()
        if(@follower_id == @followee_id)
            return
        end

        db = Db.get()
        if(Follow.find_by(follower_id: @follower_id, followee_id: @followee_id))
            db.execute("UPDATE follows SET follower_id = ?, followee_id = ?, date = ?;", @follower_id, @followee_id, @date)
        else
            db.execute("INSERT INTO follows(follower_id, followee_id, date) values(?,?,?);", @follower_id, @followee_id, @date)
        end
    end

    def destroy()
        db = Db.get()
        db.execute("DELETE FROM follows WHERE follower_id = ? AND followee_id = ?", @follower_id, @followee_id)
    end

    def self.where(follower_id: nil, followee_id: nil, limit: nil)
        search_strings = getSearchStrings(follower_id, followee_id)
                
        queryString = "SELECT * FROM follows"
        queryString += createSearchString(search_strings)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    def self.find_by(follower_id: nil, followee_id: nil)
        return where(follower_id: follower_id, followee_id: followee_id, limit: 1)[0]
    end

    def self.create(follower_id, followee_id)
        db = Db.get()

        newFollow = Follow.new(follower_id, followee_id, DateTime.now().to_time().to_i())
        newFollow.save()
    end

    def self.initFromDBData(data)
        return Follow.new(data['follower_id'], data['followee_id'], getCreationTime(data['date']))
    end

    private 
    def self.getSearchStrings(follower_id, followee_id)
        search_strings = []

        Follow.addStringToQuery("follows.follower_id", follower_id, search_strings)
        Follow.addStringToQuery("follows.followee_id", followee_id, search_strings)

        return search_strings
    end
end