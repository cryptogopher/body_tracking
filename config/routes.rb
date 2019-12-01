# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects, shallow: true do
  resources :body_trackers, only: [:index] do
    collection do
      post 'defaults'
      resources :measurements, only: [:index, :create, :edit, :update, :destroy] do
        get 'retake', on: :member
      end
      resources :ingredients, only: [:index, :create, :destroy] do
        post 'toggle', on: :member
        collection do
          get 'nutrients'
          get 'filter'
          get 'filter_nutrients'
          post 'toggle_nutrient_column'
          post 'import'
        end
      end
      resources :sources, only: [:index, :create, :destroy]
      resources :quantities, only: [:index, :create, :edit, :update, :destroy] do
        member do
          post 'toggle'
          post 'move/:direction', to: 'quantities#move', as: :move
        end
        collection do
          get 'parents'
          get 'filter'
        end
      end
      resources :units, only: [:index, :create, :destroy]
    end
  end
end
