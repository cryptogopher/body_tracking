# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects do
  shallow do
    resources :body_trackers, :only => [:index] do
      post 'defaults', on: :collection
    end
    resources :measurements, :only => [:index, :create, :destroy] do
      post 'toggle', on: :member
    end
    resources :ingredients, :only => [:index, :create, :destroy] do
      post 'toggle', on: :member
      collection do
        get 'nutrients'
        get 'filter'
        get 'filter_nutrients'
        post 'toggle_nutrient_column'
        post 'import'
      end
    end
    resources :sources, :only => [:index, :create, :destroy]
    resources :quantities, :only => [:index, :create, :edit, :update, :destroy] do
      member do
        post 'toggle'
        post 'move/:direction', to: 'quantities#move', as: :move
      end
      get 'filter', on: :collection
    end
    resources :units, :only => [:index, :create, :destroy]
  end
end
