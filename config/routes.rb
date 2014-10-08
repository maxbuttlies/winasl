Winasl::Application.routes.draw do
	get "blog/index"
	get "feed" => "blog#feed",  :defaults => { :format => 'atom' }
	get ':post' => 'blog#post'
	get ':year/:month/:day/:name' => 'blog#post'
	get 's/:site' => 'blog#site'
	get 'p/:page' => 'blog#index'


	get '404' => 'blog#site404'

	if Rails.env.production?
		get '404', :to => 'application#page_not_found'
		get '422', :to => 'application#server_error'
		get '500', :to => 'application#server_error'
	end

	root 'blog#index'
end
