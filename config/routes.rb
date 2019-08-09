# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  shallow do
    resources :body_trackers, :controller => 'body_trackers', :only => [:index]
  end
end
