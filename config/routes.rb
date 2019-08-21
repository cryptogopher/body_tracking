# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  shallow do
    resources :body_trackers, :only => [:index]
    resources :units, :only => [:new, :index, :create, :destroy] do
      post 'import', on: :collection
    end
  end
end
