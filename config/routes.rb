Rails.application.routes.draw do
  
  resources :notifications, only: [] do
    collection do 
      get 'detailed_homepage'
      get 'sample_homepage'
      post 'optin'
      post 'optout'
      post 'send_msg'
      post 'webhook'
    end
    member do
      post 'change_optin'
    end
  end
  
  root 'notifications#sample_homepage'
  
end
