# frozen_string_literal: true

Rails.application.routes.draw do
  get 'service/authorize'
  get 'service/callback'

  get 'fat/authorize'
  get 'fat/callback'

  get 'hello/index'
  get 'hello/signout'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'hello#index'
end
