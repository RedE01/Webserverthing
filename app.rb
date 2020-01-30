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
		@posts = @db.execute("SELECT * FROM posts ORDER BY id DESC;")

		return slim(:startpage)
	end

	
	get '/login' do
		return slim(:login)
	end
	
	post '/login' do
		user = @db.execute("SELECT id, password FROM users WHERE name IS ?;", params['username']).first
		if(user == nil)
			return redirect('/login')
		end
		
		db_hash = BCrypt::Password.new(user['password'])

		if(db_hash == params['password'])
			session['user_id'] = user['id']
			return redirect('/')
		end
		
		return redirect('/login')
	end
	
	post '/logout' do
		session['user_id'] = nil
		return redirect('/')
	end

	get '/post/new' do
		return slim(:"post/new")
	end
	
	post '/post' do
		if(session['user_id'] == nil)
			return redirect('/')
		end
		
		image_id = nil
		if(params[:image])
			tempFile = params[:image][:tempfile]

			# filename = "#{session['user_id']}-#{time.year}-#{time.month}-#{time.day}-#{time.hour}-#{time.min}-#{time.sec}"
			dirname = "./public/posts/images/#{session['user_id']}"
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end
			filesInDir = Dir.glob(File.join(dirname, '**', '*')).select { |file| File.file?(file) }.count
			
			filename = params[:image][:filename]
			fileExtension = File.extname(filename)
			FileUtils.cp(tempFile, "#{dirname}/#{filesInDir.to_s}#{fileExtension}")

			image_id = filename.to_i
		end

		@db.execute("INSERT INTO posts (user_id, title, content, image_id) VALUES (?, ?, ?, ?);", session['user_id'], params['title'], params['content'], image_id)

		return redirect('/')
	end

	get '/post/:id' do
		@post = @db.execute("SELECT * FROM posts WHERE id=?;", params['id']).first
		
		return slim(:"post/view")
	end
end