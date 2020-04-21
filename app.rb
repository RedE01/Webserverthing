require_relative("model/Db.rb")
require_relative("model/User.rb")
require_relative("model/Post.rb")
require_relative("model/Rating.rb")
require_relative("model/Follow.rb")
require_relative("./misc.rb")
require_relative("./login_handler.rb")

class App < Sinatra::Base
	
	enable :sessions
	
	before do 
		if(session[:user_id] == nil)
			@current_user = nil
		else
			@current_user = User.find_by(id: session[:user_id])
		end
	end

	get '/' do
		if(params['show'] == "following")
			@posts = Post.where(current_user_id: session[:user_id], parent_post_id: "NULL", exist: 1, follower_id: session[:user_id])
			@showFollowing = true
		else
			@posts = Post.where(current_user_id: session[:user_id], parent_post_id: "NULL", exist: 1, order: [Pair.new("posts.id", "DESC")])
		end

		return slim(:index)
	end
	
	get '/login' do
		return slim(:login)
	end
	
	post '/login' do
		user = LoginHandler.login(params['username'], params['password'])
		if(user)
			session.clear()
			session[:user_id] = user.id
			return redirect("/")
		end

		return redirect("/login")
	end
	
	post '/logout' do
		session[:user_id] = nil
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
		if(@current_user == nil)
			return redirect(back)
		end

		Rating.create(params[:post], @current_user.id, params['rating'])

		return redirect(back)
	end

	get '/post/new' do
		return slim(:"post/new")
	end
	
	post '/post' do
		if(@current_user == nil)
			return redirect('/')
		end
		
		image_name = nil
		if(params[:image])
			tempFile = params[:image][:tempfile]

			dirname = "./public/posts/images/#{session[:user_id]}"
			unless File.directory?(dirname)
				FileUtils.mkdir_p(dirname)
			end
			filesInDir = Dir.glob(File.join(dirname, '**', '*')).select { |file| File.file?(file) }.count
			
			filename = params[:image][:filename]
			fileExtension = File.extname(filename)
			FileUtils.cp(tempFile, "#{dirname}/#{filesInDir.to_s}#{fileExtension}")

			image_name = filesInDir.to_s + fileExtension
		end

		Post.create(session[:user_id], params['title'], params['content'], image_name, nil, nil, 0)

		return redirect('/')
	end

	post '/post/:base_post_id/:parent_post_id/:depth' do
		if(@current_user== nil)
			return redirect('/')
		end

		depth = 0
		if(params['depth'])
			depth = params['depth']
		end

		if(params['content'] != "")
			Post.create(session[:user_id], params['title'], params['content'], nil, params['parent_post_id'], params['base_post_id'], depth)
		end

		return redirect(back)
	end

	post '/post/delete/:id' do
		post = Post.find_by(id: params['id'])
		if(post == nil)
			return redirect(back)
		end

		if(@current_user && post.user_id == @current_user.id)
			post.destroy()
		end

		return redirect(back)
	end

	get '/post/:id' do
		@post = Post.find_by(current_user_id: session[:user_id], id: params['id'])
		if(@post == nil)
			return redirect("/")
		end

		comments_list = Post.where(current_user_id: session[:user_id], base_post_id: params['id'], order: [Pair.new("posts.depth", "ASC"), Pair.new("posts.id", "DESC")])

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

		if(@current_user != nil)
			@isFollowing = Follow.find_by(follower_id: @current_user.id, followee_id: params['id'])
			if(@isFollowing == nil)
				@isFollowing = false
			else
				@isFollowing = true;
			end
		end

		@showRatingsSelected = false
		
		if(params['show'] == "ratings")
			@showRatingsSelected = true;
			@ratings = Rating.where(current_user_id: session[:user_id], user_id: params['id'])
		else
			@userPosts = Post.where(current_user_id: session[:user_id], user_id: params['id'])
		end

		return slim(:"user/view")
	end

	post '/follow/:follower/:followee' do
		if(@current_user != nil && @current_user.id == params['follower'].to_i())
			Follow.create(params['follower'].to_i, params['followee'].to_i)
		end
		return redirect(back)
	end

	post '/unfollow/:follower/:followee' do
		if(@current_user != nil && @current_user.id == params['follower'].to_i())
			follow = Follow.find_by(follower_id: params['follower'], followee_id: params['followee'])
			if(follow)
				follow.destroy()
			end
		end
		return redirect(back)
	end

	post '/user/delete/:id' do
		if(@current_user != nil && @current_user.id == params['id'].to_i())
			@current_user.destroy();
			session[:user_id] = nil
		end
		return redirect("/")
	end

end