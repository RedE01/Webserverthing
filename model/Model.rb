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
    def self.createOrderString(collumn, order)
        if(order == nil)
            return ""
        end

        return " ORDER BY #{collumn} #{order}"
    end

end