# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects, shallow: true do
  resources :body_trackers, only: [:index] do
    collection do
      post 'defaults'
    end
  end
  resources :goals, only: [:show, :edit] do
    member do
      post 'toggle_exposure', to: 'goals#toggle_exposure'
    end
  end
  resources :targets, except: [:show, :edit] do
    collection do
      get 'edit/:date', to: 'targets#edit', as: :edit
      post 'reapply/:date', to: 'targets#reapply', as: :reapply
    end
  end
  resources :ingredients, only: [] do
    post 'adjust/:adjustment', to: 'meals#adjust', as: :adjust, on: :member
  end
  resources :meals, except: [:show] do
    member do
      get 'edit_notes'
      patch 'update_notes'
      post 'toggle_eaten'
    end
    collection do
      post 'toggle_exposure'
    end
  end
  resources :measurement_routines, only: [:show, :edit] do
    member do
      get 'readouts', to: 'measurements#readouts'
      post 'toggle_exposure', to: 'measurements#toggle_exposure'
    end
  end
  resources :measurements, except: [:show] do
    member do
      get 'retake'
    end
    collection do
      get 'filter'
    end
  end
  resources :foods, except: [:show] do
    post 'toggle', on: :member
    collection do
      get 'nutrients'
      post 'toggle_exposure'
      get 'filter'
      get 'autocomplete'
      post 'import'
    end
  end
  resources :sources, only: [:index, :create, :destroy]
  resources :quantities, except: [:show] do
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
