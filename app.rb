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
		@posts = @db.execute("SELECT * FROM posts;")

		slim :startpage
	end

	get '/post/:id' do
		@post = @db.execute("SELECT * FROM posts WHERE id=?;", params['id']).first
		slim :"post/view"
	end

	get '/login' do
		slim :login
	end

	post '/login' do
		user = @db.execute("SELECT id, password FROM users WHERE name IS ?;", params['username']).first
		if(user == nil)
			redirect '/login'
		end

		db_hash = BCrypt::Password.new(user['password'])

		if(db_hash == params['password'])
			session['user_id'] = user['id']
			p "logged in"
			redirect '/'
		end

		redirect '/login'
	end

	post '/logout' do
		session['user_id'] = nil
		redirect '/'
	end
	
end