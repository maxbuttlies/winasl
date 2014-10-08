require "rss"

class BlogController < ApplicationController
	@files_size = 0
	def index
		count = 5
		if params[:page] == nil
			page = 0
		else
			page = params[:page].to_i - 1
		end
		@posts = list_posts count,page

		while @files_size%count != 0
			@files_size = @files_size+1
		end
		@older = page+1 < @files_size/count ? '/p/'+(page+2).to_s : ''
		@newer =  page > 0 ? '/p/'+(page).to_s : ''
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

	def feed
		@posts = list_posts 10, 0
	end

	:private
	def open_post file
		tmp_file = file.gsub '.md', ''
		if not  file.split('/').last.include?'.'
			if File.exists?file+'.png' and not File.exist?file+'.md' 
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
				if File.exists?tmp_file+'.png'
					image = tmp_file.gsub public_dir, ''			
					image = '<a href="'+image+'.png"><img src="'+image+'.png"/></a>' 	
					post.content = image+post.content
				end 		
			elsif file.end_with?'.png' or file.end_with?'.jpg'
				image = file.gsub public_dir, ''
				post.content = '<img src="'+image+'"/>'
				post.tweet = 'Hey, schau Dir mal dieses Bild an!'
			end
			name = file.split('/').last.split('.').first
			post.date = name[6,2] +'.' + name[4,2] + '.' + name[0,4]
			post.file = name[0,4] + '/' + name[4,2] + '/' + name[6,2] + '/' + name.split('-').last
			post.published = Date.parse(post.date).to_datetime.rfc3339
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
		File.dirname(__FILE__) + "/../../public/"
	end
	def clear_string string
		string[2,string.length]
	end
	def list_posts count, page

		posts = Array.new
		files  = Dir[public_dir + posts_dir+'*'].sort.reverse
		@files_size = files.size
		first = count*page 
		if  first < files.size 
			last = first + count
			last = files.size if last > files.size  

			files[first...last].each do | file |
				if file.end_with?'png'
					test_file = file.gsub '.png','.md'
					if not File.exists?test_file
						posts.push open_post file
					end
				else 
					posts.push open_post file
				end
			end
		end
		posts
	end
end
