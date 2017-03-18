Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

	resources :bike_stations, only:[:index]
	get "/v1/ubike-station/taipei", to: 'bike_station#index'	
end
