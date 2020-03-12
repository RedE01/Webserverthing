require_relative("model/Db.rb")
require_relative("model/User.rb")
require_relative("model/Post.rb")
require_relative("./misc.rb")

class CommentNode
    attr_reader :post, :children

    def initialize(post)
        @post = post
        @children = []
    end

    def addChild(commen_node)
        @children << commen_node
    end
end

class App < Sinatra::Base
	
	enable :sessions
	
	before do 
		# session['user_id'] = 1

		@db = Db.get()

		@userInfo = nil
		if(session['user_id'] != nil)
			@userInfo = User.find_by(id: session['user_id'])[0]
		end
		
	end

	get '/' do
		@posts = Post.find_by(parent_post_id: "NULL", order: [Pair.new("posts.id", "DESC")])
		Post.find_by()

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
		user = User.find_by(name: params['username'])[0]

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
		if(params['password'] != params['passwordConfirm'])
			return redirect('/user/new')
		end

		user = User.find_by(name: params['username'])[0]
		
		if(user != nil)
			return redirect('/user/new')
		end
		
		User.insert(params['username'], params['password'])
		
		#Login and stuff

		return redirect('/login')
	end

	get '/post/new' do
		return slim(:"post/new")
	end
	
	post '/post' do
		if(session['user_id'] == nil)
			return redirect('/')
		end
		
		image_name = nil
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

			image_name = filesInDir.to_s + fileExtension
		end

		Post.insert(session['user_id'], params['title'], params['content'], image_name, nil, nil, 0)

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
			Post.insert(session['user_id'], params['title'], params['content'], nil, params['parent_post_id'], params['base_post_id'], depth)
		end

		return redirect(back)
	end

	get '/post/:id' do
		@post = Post.find_by(id: params['id'])[0]
		comments_list = Post.find_by(base_post_id: params['id'], order: [Pair.new("posts.depth", "ASC"), Pair.new("posts.id", "DESC")])
		# comments_list = @db.execute("SELECT posts.*, users.name FROM posts INNER JOIN users ON posts.user_id = users.id WHERE base_post_id=? ORDER BY posts.depth ASC, posts.id DESC;", params['id'])

		@comments = []
		comments_hash = Hash.new()
		comments_list.each do |comment|
			newCommentNode = CommentNode.new(comment)
			
			comments_hash[comment.id] = newCommentNode
			parentCommentNode = comments_hash[comment.parent_post_id]
			if(parentCommentNode)
				parentCommentNode.addChild(newCommentNode)
			else
				@comments << newCommentNode
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