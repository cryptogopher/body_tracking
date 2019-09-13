# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  shallow do
    resources :body_trackers, :only => [:index] do
      post 'defaults', on: :collection
    end
    resources :ingredients, :only => [:index, :create, :destroy]
    resources :quantities, :only => [:index, :create, :destroy]
    resources :units, :only => [:index, :create, :destroy]
  end
end
