require_relative("model/Db.rb")
require_relative("model/User.rb")

class CommentNode
    attr_accessor :value, :children

    def initialize(values)
        @values = values
        @children = []
    end

    def addChild(value)
        @children << value
    end

    def getValues()
        return @values
    end
end

class App < Sinatra::Base
	
	enable :sessions
	
	before do 
		# session['user_id'] = 1

		@db = Db.get()

		@userInfo = []
		if(session['user_id'] != nil)

			@userInfo = @db.execute("SELECT * FROM users WHERE id = ?;", session['user_id'])[0]
		end
		
	end

	get '/' do
		@posts = @db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE posts.parent_post_id IS NULL ORDER BY posts.id DESC;")

		return slim(:startpage)
	end

	get '/followingPosts' do
		@posts = @db.execute("SELECT posts.*, users.name FROM posts INNER JOIN follows ON posts.user_id = follows.followee_id INNER JOIN users ON posts.user_id = users.id  WHERE posts.parent_post_id IS NULL AND follows.follower_id = ?", session['user_id'])

		return slim(:followingPosts)
	end
	
	get '/login' do
		return slim(:login)
	end
	
	post '/login' do
		# user = @db.execute("SELECT id, password FROM users WHERE name IS ?;", params['username']).first
		user = User.find_by(name: params['username'])
		if(user == nil)
			return redirect('/login')
		end
		
		db_hash = BCrypt::Password.new(user.password)

		if(db_hash == params['password'])
			session['user_id'] = user.id
			return redirect('/')
		end
		
		return redirect('/login')
	end
	
	post '/logout' do
		session['user_id'] = nil
		return redirect('/')
	end

	get '/user/new' do
		return slim(:"user/new")
	end

	post '/user/new' do
		user = @db.execute("SELECT id FROM users WHERE name IS ?;", params['username'])[0]
		if(user != nil)
			return redirect('/user/new')
		end

		hashedPassword = BCrypt::Password.create(params['password'])
		@db.execute("INSERT INTO users(name, password) VALUES (?, ?);", params['username'], hashedPassword)
		
		#Login and stuff

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

		@db.execute("INSERT INTO posts (user_id, title, content, image_id, depth) VALUES (?, ?, ?, ?, 0);", session['user_id'], params['title'], params['content'], image_id)

		return redirect('/')
	end

	post '/post/:base_post_id/:parent_post_id/:depth' do
		if(session['user_id'] == nil)
			return redirect('/')
		end

		depth = 0
		if(params['depth'])
			depth = params['depth']
		end

		if(params['content'] != "")
			@db.execute("INSERT INTO posts (user_id, title, content, parent_post_id, base_post_id, depth) VALUES (?, ?, ?, ?, ?, ?);", session['user_id'], params['title'], params['content'], params['parent_post_id'], params['base_post_id'], depth)
		end

		return redirect(back)
	end

	get '/post/:id' do
		@post = @db.execute("SELECT posts.*, users.name AS username FROM posts INNER JOIN users ON posts.user_id = users.id WHERE posts.id=?;", params['id']).first
		comments_list = @db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE base_post_id=? ORDER BY posts.depth ASC, posts.id DESC;", params['id'])

		@comments = []
		comments_hash = Hash.new()
		comments_list.each do |comment|
			newComment = CommentNode.new(comment)
			
			comments_hash[comment['id']] = newComment
			parentComment = comments_hash[comment['parent_post_id']]
			if(parentComment)
				parentComment.addChild(newComment)
			else
				@comments << newComment
			end
		end

		return slim(:"post/view")
	end

	get '/user/:id' do
		@username = @db.execute("SELECT name FROM users WHERE id = ?;", params['id'])[0]['name']
		@userPosts = @db.execute("SELECT post.*, basePost.title AS basePostTitle FROM posts AS post LEFT JOIN posts AS basePost ON post.base_post_id = basePost.id WHERE post.user_id = ?;", params['id'])

		return slim(:"user/view")
	end
end