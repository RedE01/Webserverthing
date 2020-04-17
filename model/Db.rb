class Db
    def self.get()
        @db = SQLite3::Database.new('db/db.db')
        @db.execute("PRAGMA foreign_keys = ON;")
        @db.results_as_hash = true
        return @db
    end

    def self.sanitize(str)
        return SQLite3::Database.quote(str)
    end
end