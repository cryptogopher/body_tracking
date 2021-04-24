# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

resources :projects, shallow: true do
  resources :body_trackers, only: [:index] do
    collection do
      post 'defaults'
    end
  end
  resources :goals, except: [:show] do
    member do
      post 'toggle_exposure', controller: :targets
    end
    resources :targets, except: [:show, :edit, :update] do
      collection do
        get 'edit/:date', action: :edit, as: :edit
        patch '', action: :update
        post 'reapply/:date', action: :reapply, as: :reapply
      end
    end
  end
  resources :ingredients, only: [] do
    member do
      post 'adjust/:adjustment', controller: :meals, action: :adjust, as: :adjust
    end
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
      get 'readouts', controller: :measurements
      post 'toggle_exposure', controller: :measurements
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
    member do
      post 'toggle'
    end
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
      post 'move/:direction', action: :move, as: :move
    end
    collection do
      get 'parents'
      get 'filter'
    end
  end
  resources :units, only: [:index, :create, :destroy]
end

get 'subthresholds', controller: :targets, action: :subthresholds, as: :subthresholds
