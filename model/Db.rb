# Configures the database and acts as an abstraction between the SQLite3 wherever the database is needed. 
class Db

    #   Public: Gets the SQLite3::Database object
    #
    #   Returns the SQLite3::Database object
    def self.get()
        @db = SQLite3::Database.new('db/db.db')
        @db.execute("PRAGMA foreign_keys = ON;")
        @db.results_as_hash = true
        return @db
    end

    #   Public: Sanitize the input by quoting the string making it safe to use in an SQL statement.
    #
    #   str - The string to be sanitized
    #
    #   Returns the sanitized string
    def self.sanitize(str)
        return SQLite3::Database.quote(str)
    end
end