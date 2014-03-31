class BlogController < ApplicationController

	def index
		@posts = Array.new
		files  = Dir[public_dir + posts_dir+'*'].sort.reverse

		files.each do | file |
			@posts.push open_post file

		end
	end

	def post
		if not params[:post] == nil
			postname = params[:post]	
		elsif not params[:year]  == nil
			if not params[:month]  == nil 
				if not params[:day]  == nil
					if not params[:name] == nil
						postname = params[:year] + params[:month] + params[:day] + '-' + params[:name]
					end
				end
			end
		end
		@post = open_post public_dir + posts_dir+postname		
	end


	def site
		@content = Maruku.new(File.new(public_dir + sites_dir + params[:site] + '.md').read).to_html
	end



	:private
	def open_post file
		if not  file.split('/').last.include?'.'
			if File.exists?file+'.png' 
				file = file+'.png'
			elsif File.exists?file+'.jpg'
				file = file+'.jpg'
			else
				file = file +'.md'
			end
		end
		if not File.exists?file
			redirect_to '/s/404'
		else
			post = Post.new
			if file.end_with?'.md'
				post.content = File.new(file).read
				post.content.gsub! '\n', '<br>'
				post.content = post.content[0, post.content.length-1] if post.content.end_with? '\\' 	
				post.content = Maruku.new(post.content).to_html
				post.tweet = Sanitize.clean post.content[0,130]
			
			elsif file.end_with?'.png' or file.end_with?'.jpg'
				image = file.gsub public_dir, ''
				post.content = '<img src="'+image+'"/>'
				post.tweet = 'Hey, schau Dir mal dieses Bild an!'
			end
			name = file.split('/').last.split('.').first
			post.date = name[6,2] +'.' + name[4,2] + '.' + name[0,4]
			post.file = name[0,4] + '/' + name[4,2] + '/' + name[6,2] + '/' + name.split('-').last

			post
		end
	end

	def posts_dir 
		"/posts/"
	end
	def sites_dir
		"sites/"
	end
	def public_dir
		puts File.dirname(__FILE__) + "/../../public/"

		File.dirname(__FILE__) + "/../../public/"
	end
	def clear_string string
		string[2,string.length]
	end
end
