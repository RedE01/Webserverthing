class Model

    # Public: Returns all objects in database of the same type as the derived class it is called from.
    #
    # Returns the array of objects.
    def self.all()
        return where()
    end

    # Public: Returns the first object in the database of the same type as the derived class it it called from.
    #
    # Returns the object
    def self.first()
        return find_by(order: [Pair.new("id", "ASC")])
    end

    protected
    # Internal: Appends a string of type: 'name = val' to an array and sanitieses the string to make sure that it
    # is safe to use in an SQL statemtent. If val is nil the string is not appended. To append a string
    # of type: 'name IS NULL' val should be set to NULL.
    #
    # name - The name of the collumn in database.
    # val - The value of the collumn in the database to search for.
    # array - The array that the string gets appended to.
    #
    # Returns nothing
    def self.addStringToQuery(name, val, array)
        if(val == nil)
            return
        end

        if(val == "NULL")
            array << " #{name} IS NULL"
            return
        end

        newVal = val
        if(val.is_a?(String))
            newVal = Db.sanitize(val)
            newVal = "'" + newVal + "'"
        end

        array << "#{name} = #{newVal}"
    end

    protected
    # Internal: Combine a list of strings into a single string that begins with ' WHERE ' and  
    # each string in the list is separated by ' AND '.
    #
    # search_strings - The array of strings
    #
    # Examples
    #
    #   Model.createSearchString(["example = 3", "example2 = 1"])
    #   # => ' WHERE example = 3 AND example2 = 1'
    #
    # Returns the combined string
    def self.createSearchString(search_strings)
        outString = ""
        appendString = " WHERE "

        search_strings.each_with_index do |search_string, index|
            outString += appendString + search_string
            
            if(index == 0)
                appendString = " AND "
            end
        end

        return outString
    end

    def self.initFromDBData(data)
        return nil
    end

    protected
    # Internal: Takes a list of Pairs with strings and combines them into a single string that starts
    # with: ' ORDER BY ', followed by: 'pair.var1 pair.var2, ' for each pair in the list.
    #
    # order_pair_list - A list of Pairs where each pair.var1 is the collumn to order by and pair.val2
    # is either 'ASC' or 'DESC', which stands for 'accending' and 'decending' respectivly.
    #
    # Examples
    #
    #   Model.createOrderString([Pair.new("collumn_name", "DESC"), Pair.new("collumn_name2", "ASC")])
    #   # => " ORDER BY collumn_name DESC, collumn_name2 ASC"
    #
    # Returns the combined string
    def self.createOrderString(order_pair_list)
        if(order_pair_list == nil)
            return ""
        end

        result = ""
        appendString = " ORDER BY "
        order_pair_list.each_with_index do |order_pair, index|
            result += appendString + "#{order_pair.var1} #{order_pair.var2}"
            if(index == 0)
                appendString = ", "
            end
        end

        return result
    end

    # Internal: Takes an integer and returns the string " limit [limit]" where [limit] is the argument. If limit
    # is not an integer an empty string is returned.
    #
    # limit - The integer to append to the string " limit"
    #
    # Returns the string
    def self.createLimitString(limit)
        if(!limit.is_a?(Integer))
            return ""
        end

        return " limit #{limit}"
    end

    # Internal: Converts an integer into a DateTime.
    #
    # date - Integer represeting the number of seconds since the Epoch.
    #
    # Returns the date as a DateTime.
    def self.getCreationTime(date)
        return Time.at(date.to_i()).to_datetime()
    end

    # Internal: Executes an SQL query and uses the data to populate a list of Model object
    #
    # queryString - The SQL query
    #
    # Returns an array of Model objects
    def self.makeObjectArray(queryString)
        db = Db.get()

        model_db = db.execute(queryString)

        return_array = []
        
        model_db.each do |data|
            return_array << initFromDBData(data)
        end

        return return_array
    end

end