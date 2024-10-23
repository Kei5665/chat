Rails.application.routes.draw do
  root 'openai/chats#new'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  namespace :openai do
    resources :chats
    # セッションリセット用のルートを追加
    post '/reset_session', to: 'chats#reset_session'
    # ユーザー名を設定するルートを追加
    post '/set_name', to: 'chats#set_name'
    # 面接内容を保存
    post '/summarize_and_save', to: 'chats#summarize_and_save'

  end
  # Defines the root path route ("/")
  # root "posts#index"
end
