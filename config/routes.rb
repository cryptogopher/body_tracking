# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects, shallow: true do
  resources :body_trackers, only: [:index] do
    collection do
      post 'defaults'
    end
  end
  resources :meals, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :measurement_routines, only: [:show, :edit] do
    member do
      get 'readouts', to: 'measurements#readouts'
      post 'toggle_column', to: 'measurements#toggle_column'
    end
  end
  resources :measurements, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      get 'retake'
    end
    collection do
      get 'filter'
    end
  end
  resources :ingredients, only: [:index, :new, :create, :edit, :update, :destroy] do
    post 'toggle', on: :member
    collection do
      get 'nutrients'
      post 'toggle_column'
      get 'filter'
      post 'import'
    end
  end
  resources :sources, only: [:index, :create, :destroy]
  resources :quantities, only: [:index, :new, :create, :edit, :update, :destroy] do
    member do
      get 'new_child'
      post 'create_child'
      post 'move/:direction', to: 'quantities#move', as: :move
    end
    collection do
      get 'parents'
      get 'filter'
    end
  end
  resources :units, only: [:index, :create, :destroy]
end
