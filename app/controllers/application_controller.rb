class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	def page_not_found
		respond_to do |format|
			format.html { redirect_to '/s/404' } 
					
			format.all  { render nothing: true, status: 404 }
		end
	end

	def server_error
		respond_to do |format|
			format.html { redirect_to '/s/404' } 
			
			format.all  { render nothing: true, status: 500}
		end
	end
end
