class App < Sinatra::Base
	
	enable :sessions
	
	before do 
		@db = SQLite3::Database.new('db/db.db')
		@db.results_as_hash = true
		
		if !@user_id
			
			@user_id = session['user_id']
			
		end
		
	end

	get '/' do
		


		slim :startpage
	end



	
end