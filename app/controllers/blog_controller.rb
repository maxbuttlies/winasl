require "rss"
require "net/imap"
require "mail"

class BlogController < ApplicationController
	@files_size = 0


	def index
		fetch_mails
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
		elsif not params[:name] == nil
			postname = params[:year] + params[:month] + params[:day] 
			if not params[:time] == nil
				postname += 'T' + params[:time]
			end
			postname += '-' + params[:name]		
		end
		@post = open_post posts_dir+postname		
	end

	def site
		@content = Maruku.new(File.new(sites_dir + params[:site] + '.md').read).to_html
	end

	def feed
		@posts = list_posts 10, 0
	end

	def imap
		render text: fetch_mails
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
					image = '/posts/'+tmp_file.split('/').last			
					image = '<a href="'+image+'.png"><img src="'+image+'.png"/></a>' 	
					post.content = image+post.content
				end 		
			elsif file.end_with?'.png' or file.end_with?'.jpg'
				image = image = '/posts/'+tmp_file.split('/').last	
				post.content = '<img src="'+image+'"/>'
				post.tweet = 'Hey, schau Dir mal dieses Bild an!'
			end
			name = file.split('/').last.split('.').first
			post.date = name[6,2] +'.' + name[4,2] + '.' + name[0,4]
			time_part = ''

			if name[8, 1] == 'T'
				time_part = name[9,4] + '/'	
			end
			post.file = '/' + name[0,4] + '/' + name[4,2] + '/' + name[6,2] + '/' +time_part+ name.split('-').last

			post.published = Date.parse(post.date).to_datetime.rfc3339
			post
		end
	end

	def posts_dir 
		find_public 'posts'
	end

	def sites_dir
		find_public 'sites'
	end

	def find_public dir
		Rails.root.join('public', dir).to_s+'/'
	end

	def list_posts count, page

		posts = Array.new

		files  = Dir[posts_dir+'*'].sort.reverse
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

	def fetch_mails
		message = "nothing"
		Mail.defaults do
			retriever_method :pop3, 
			:address    => APP_CONFIG['mailpublish']['server'],
			:port       => APP_CONFIG['mailpublish']['port'],
			:user_name  => APP_CONFIG['mailpublish']['username'],
			:password   => APP_CONFIG['mailpublish']['password'],
			:enable_ssl => APP_CONFIG['mailpublish']['ssl']
		end

		Mail.find_and_delete.each { |mail|
			if mail.from[0] == APP_CONFIG['mailpublish']['allowed_mail']
				post_name = DateTime.now.strftime("%Y%m%dT%H%M-") +mail.subject 
				post_content = mail.body.decoded

				if mail.multipart?
					message = "multipart"
					mail.attachments.each do | attachment |
						if (attachment.content_type.start_with?('image/'))
							filename = post_name+".png"
							File.open(posts_dir + filename, "w+b", 0644) {|f| f.write attachment.body.decoded}
							post_content = mail.text_part.body.decoded						
						end
					end
				end
			end
			File.open(posts_dir+post_name+".md", 'w') { |file| 
				file.write(post_content) 
			}
		}
		message
	end
end
