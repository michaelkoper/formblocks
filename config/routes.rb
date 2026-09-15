# frozen_string_literal: true

Formblocks::Engine.routes.draw do
  # The engine's own CSS and JavaScript, served same-origin (see Formblocks::Assets).
  get 'assets/:name', to: 'assets#show', as: :engine_asset, format: false, constraints: { name: /[\w.-]+/ }

  # Global brand settings — declared before the forms so `/settings` is never
  # read as a form id.
  resource :settings, only: %i[show update]

  # Flat, human URLs: the mount path IS the forms index. /forms is the list,
  # /forms/new the template picker, /forms/12/edit the builder.
  resources :forms, path: '', except: :show do
    member do
      post :duplicate
      post :publish
      post :unpublish
      get :published
      get :settings
    end

    resources :pages, only: %i[create update destroy] do
      member { patch :move }

      resources :blocks, only: %i[create update destroy] do
        member { patch :move }
        collection { patch :reorder }
      end
    end

    resources :responses, only: %i[index show destroy]
  end

  root to: 'forms#index'
end
