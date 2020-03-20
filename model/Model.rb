class Model

    protected
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

    protected
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

    def self.getCreationTime(date)
        return Time.at(date.to_i()).to_datetime()
    end

end