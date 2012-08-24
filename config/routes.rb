Rails.application.routes.draw do
  resources :nearby, :controller => "blacklight_browse_nearby"
end
