# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects, shallow: true do
  resources :body_trackers, only: [:index] do
    collection do
      post 'defaults'
      resources :measurements, only: [:index, :new, :create, :edit, :update, :destroy] do
        member do
          get 'retake'
          get 'readouts'
          post 'toggle_column'
        end
        collection do
          get 'filter'
        end
      end
      resources :ingredients, only: [:index, :create, :destroy] do
        post 'toggle', on: :member
        collection do
          get 'nutrients'
          get 'filter'
          get 'filter_nutrients'
          post 'import'
          post 'toggle_column'
        end
      end
      resources :sources, only: [:index, :create, :destroy]
      resources :quantities, only: [:index, :create, :edit, :update, :destroy] do
        member do
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
