# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  shallow do
    resources :body_trackers, :only => [:index] do
      post 'defaults', on: :collection
    end
    resources :ingredients, :only => [:index, :create, :destroy] do
      post 'toggle', on: :member
      post 'import', on: :collection
      get 'nutrients', on: :collection
      post 'toggle_nutrient_column', on: :collection
    end
    resources :sources, :only => [:index, :create, :destroy]
    resources :quantities, :only => [:index, :create, :destroy] do
      post 'toggle', on: :member
      post 'up', 'down', 'left', 'right', on: :member
    end
    resources :units, :only => [:index, :create, :destroy]
  end
end
