require_relative("model/Db.rb")
require_relative("model/User.rb")
require_relative("model/Post.rb")
require_relative("model/Rating.rb")
require_relative("./misc.rb")

class App < Sinatra::Base
	
	enable :sessions
	
	before do 
		# session['user_id'] = 2

		User.setCurrentUser(session['user_id'])
		
	end

	get '/' do
		if(params['show'] == "following")
			@posts = Post.where(parent_post_id: "NULL", exist: 1, follower_id: session['user_id'])
			@showFollowing = true
		else
			@posts = Post.where(parent_post_id: "NULL", exist: 1, order: [Pair.new("posts.id", "DESC")])
		end

		return slim(:startpage)
	end
	
	get '/login' do
		return slim(:login)
	end
	
	post '/login' do
		if(User.login(params['username'], params['password']))
			session['user_id'] = User.getCurrentUser().id
			return redirect("/")
		end

		return redirect("/login")
	end
	
	post '/logout' do
		session['user_id'] = nil
		User.setCurrentUser(nil)
		return redirect('/')
	end
	
	get '/user/new' do
		return slim(:"user/new")
	end
	
	post '/user/new' do
		if(params['password'] != params['passwordConfirm'])
			return redirect('/user/new')
		end
		
		user = User.find_by(name: params['username'])
		
		if(user != nil)
			return redirect('/user/new')
		end
		
		User.create(params['username'], params['password'])
		
		return redirect('/login')
	end
	
	post '/post/rate/:post/:rating' do
		if(User.getCurrentUser() == nil)
			return redirect(back)
		end

		post = Post.find_by(id: params[:post])
		post.rate(params['rating'], User.getCurrentUser().id)

		return redirect(back)
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

		Post.create(session['user_id'], params['title'], params['content'], image_name, nil, nil, 0)

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
			Post.create(session['user_id'], params['title'], params['content'], nil, params['parent_post_id'], params['base_post_id'], depth)
		end

		return redirect(back)
	end

	post '/post/delete/:id' do
		post = Post.find_by(id: params['id'])
		if(post == nil)
			return redirect(back)
		end

		if(post.user_id != User.getCurrentUser().id)
			return redirect(back)
		end

		post.delete()

		return redirect(back)
	end

	get '/post/:id' do
		@post = Post.find_by(id: params['id'])
		if(@post == nil)
			return redirect("/")
		end

		comments_list = Post.where(base_post_id: params['id'], order: [Pair.new("posts.depth", "ASC"), Pair.new("posts.id", "DESC")])

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
		@user = User.find_by(id: params['id'])
		if(@user == nil)
			return redirect("/")
		end
		@showRatingsSelected = false
		
		if(params['show'] == "ratings")
			@showRatingsSelected = true;
			@ratings = Rating.where(user_id: params['id'])
		else
			@userPosts = Post.where(user_id: params['id'])
		end

		return slim(:"user/view")
	end

end