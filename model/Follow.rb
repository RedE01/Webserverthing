require_relative("Db.rb")
require_relative("Model.rb")

# Takes care of interactions between the webserver and the database for Follow objects. The follow objects
# describe a many to many to many relation between users where one user if following another user.
class Follow < Model
    attr_reader :follower_id, :followee_id, :date

    def initialize(follower_id, followee_id, date)
        @follower_id = follower_id
        @followee_id = followee_id
        @date = date
    end

    # Public: Saves the Follow object to database or updates the values if it already exists
    #
    # Returns nothing
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

    # Public: Removes the Follow object from database
    #
    # Returns nothing
    def destroy()
        db = Db.get()
        db.execute("DELETE FROM follows WHERE follower_id = ? AND followee_id = ?", @follower_id, @followee_id)
    end

    # Public: Find all Follow objects that match the arguments, if an argument is nil it is ignored.
    #
    # follower_id - The follower_id to seach for.
    # followee_id - The followee_id to seach for.
    # limit - Specifiec how many objects to return.
    #
    # Returns a list of 'Follow' objects that match the search arguments.
    def self.where(follower_id: nil, followee_id: nil, limit: nil)
        search_strings = getSearchStrings(follower_id, followee_id)
                
        queryString = "SELECT * FROM follows"
        queryString += createSearchString(search_strings)
        queryString += createLimitString(limit)

        return makeObjectArray(queryString)
    end

    # Public: Find one Follow object that match the arguments, if an argument is nil it is ignored.
    #
    # follower_id - The follower_id to seach for.
    # followee_id - The followee_id to seach for.
    #
    # Returns a 'Follow' object that match the search arguments.
    def self.find_by(follower_id: nil, followee_id: nil)
        return where(follower_id: follower_id, followee_id: followee_id, limit: 1)[0]
    end

    # Public: Creates a new Follow object and saves it to the database if no such object exist.
    #
    # follower_id - The follower_id of the new object.
    # followee_id - The followee_id of the new object.
    #
    # Returns nothing.
    def self.create(follower_id, followee_id)
        db = Db.get()

        newFollow = Follow.new(follower_id, followee_id, DateTime.now().to_time().to_i())
        newFollow.save()
    end

    # Public: Creates a new Follow object, but don't save it to the database.
    #
    # data - The Hash of data with keys: 'follower_id', 'followee_id', 'date'.
    #
    # Returns the Follow object
    def self.initFromDBData(data)
        return Follow.new(data['follower_id'], data['followee_id'], getCreationTime(data['date']))
    end

    private

    # Internal: Gets a list of sqlite query strings.
    #
    # follower_id - The value of follower_id in the database to be queried for
    # followee_id - The value of followee_id in the database to be queried for
    #
    # Returns the array of query strings
    def self.getSearchStrings(follower_id, followee_id)
        search_strings = []

        Follow.addStringToQuery("follows.follower_id", follower_id, search_strings)
        Follow.addStringToQuery("follows.followee_id", followee_id, search_strings)

        return search_strings
    end
end