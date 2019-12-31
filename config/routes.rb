Rails.application.routes.draw do
  
  resources :notifications, only: [] do
    collection do 
      get 'sample_homepage'
      post 'optin'
      post 'optout'
      post 'send_msg'
      post 'webhook'
    end
  end
  
  root 'notifications#sample_homepage'
  
end
