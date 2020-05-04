require_relative("model/Db.rb")
require_relative("model/User.rb")
require_relative("model/Post.rb")
require_relative("model/Rating.rb")
require_relative("model/Follow.rb")
require_relative("./misc.rb")
require_relative("./login_handler.rb")

# Where the routes are defined and settings are configured
class App < Sinatra::Base
	
	enable :sessions
	
	# Public: Before block, called before each route. Updates @current_user to the 
	# currently logged in user.
	#
	# Returns nothing
	before do 
		if(session[:user_id] == nil)
			@current_user = nil
		else
			@current_user = User.find_by(id: session[:user_id])
		end
	end

	# Public: Index page, show all posts. If 'show following posts' only the posts
	# from people you follow are shown.
	#
	# Returns redirect to views/index.slim
	get '/' do
		if(params['show'] == "following")
			@posts = Post.where(current_user_id: session[:user_id], parent_post_id: "NULL", exist: 1, follower_id: session[:user_id])
			@showFollowing = true
		else
			@posts = Post.where(current_user_id: session[:user_id], parent_post_id: "NULL", exist: 1, order: [Pair.new("posts.id", "DESC")])
		end

		return slim(:index)
	end
	
	# Public: Shows login screen
	get '/login' do
		return slim(:login)
	end
	
	# Public: Check credentials and, if succesfull, logs into user.
	#
	# params['username'] - Taken from textfield 'username' in form in login.slim.
	# params['password'] - Taken from textfield 'password' in form in login.slim.
	#
	# Returns redirect to index page if succesfull, redirects back to /login if not.
	post '/login' do
		if(LoginHandler.login(params['username'], params['password'], session, request.ip))
			redirect("/")
		end

		return redirect("/login")
	end

	# Public: Logs out of currenly logged in user
	post '/logout' do
		session.clear()
		return redirect('/')
	end
	
	# Public: Shows user creation page
	get '/user/new' do
		return slim(:"user/new")
	end
	
	# Public: Creates new user with provided parameters
	#
	# params['password'] - Taken from textfield 'password' in form in user/new.slim.
	# params['passwordConfirm'] - Taken from textfield 'passwordConfirm' in form in user/new.slim.
	# params['username'] - Taken from textfield 'username' in form in user/new.slim.
	#
	# Returns redirect to /login if succesful, /user/new otherwise
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
	
	# Public: Adds a rating to a post.
	#
	# params[:post] - The id of the post to be rated.
	# params[:rating] - THe rating that should be applied to the post.
	#
	# Returns redirect back
	post '/post/rate/:post/:rating' do
		if(@current_user == nil)
			return redirect(back)
		end

		Rating.create(params[:post], @current_user.id, params['rating'])

		return redirect(back)
	end

	# Public: Shows the 'create post' page
	get '/post/new' do
		return slim(:"post/new")
	end
	
	# Public: Creates a post if client is logged in, copies over an image to its appropriate 
	# folder, if one was provided.
	#
	# params[:image] - The image data provided. Taken from file field 'image' in form in post/new.slim.
	# params[:title] - The title of the post. Taken from textfield 'title' in form in post/new.slim.
	# params[:content] - The content of the post. Taken from textfield 'content' in form in post/new.slim.
	#
	# Returns redirect to index page
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

	# Public: Creates a comment post
	#
	# params[:base_post_id] - The id of the post highest up in the post chain hierarchy
	# params[:parent_post_id] - The id of the post directly above the new post in the post chain hierarchy.
	# params[:depth] - The depth(how far down the post is in the post chain hierarchy).
	# params[:title] - The title of the post. Taken from textfield 'title' in form in post/view.slim.
	# params[:content] - The content of the post. Taken from textfield 'content' in form in post/view.slim.
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

	# Public: Delete post with id if the post was created by the currenly logged in to user.
	#
	# params[:id] - The id of the post to be deleted
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

	# Public: Show a post and all its comments.
	#
	# params[:id] - The id of the post to be displayed.
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

	# Public: Show a user page, if params['show'] == "ratings", show all posts that the user has rated.
	# Otherwise, show the posts the user has created
	#
	# params[:id] - The id of the user.
	# params['show'] - If == "ratings" show ratings, otherwise show posts created by user
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

	# Public: Create a follower relation between two users if the follower is the currently logged in to user.
	#
	# params[:follower] - The user that should follower the followee.
	# params[:followee] - The user that should be followed.
	post '/follow/:follower/:followee' do
		if(@current_user != nil && @current_user.id == params['follower'].to_i())
			Follow.create(params['follower'].to_i, params['followee'].to_i)
		end
		return redirect(back)
	end

	# Public: Remove a follower relation between two users if the follower is the currently logged in to user.
	#
	# params[:follower] - The user that was following the followee.
	# params[:followee] - The user that was followed.
	post '/unfollow/:follower/:followee' do
		if(@current_user != nil && @current_user.id == params['follower'].to_i())
			follow = Follow.find_by(follower_id: params['follower'], followee_id: params['followee'])
			if(follow)
				follow.destroy()
			end
		end
		return redirect(back)
	end

	# Public: Delete a user.
	#
	# params[:id] - The id of the user to be deleted
	post '/user/delete/:id' do
		if(@current_user != nil && @current_user.id == params['id'].to_i())
			@current_user.destroy();
			session[:user_id] = nil
		end
		return redirect("/")
	end

end