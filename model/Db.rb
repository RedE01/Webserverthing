class Db
    def self.get()
        @db = SQLite3::Database.new('db/db.db')
        @db.results_as_hash = true
        return @db
    end
end