require 'json'
require 'open_uri_redirections'
class BikeStationController < ApplicationController
	def index
		@data = get_data()
		render json: @data["retVal"]
		puts params["lat"]
		puts params["lng"]
		#@data["retVal"].each do |key, value|
		h1 =  @data["retVal"]["0001"]
		puts h1
		#end
	end
private
	def get_data
		uri = "http://data.taipei/youbike"#dataa uri
		File.open("bike_data.json", "wb") do |file|
			file.write open(uri, :allow_redirections => :safe).read#download data as bike_data.json
		end

		file = File.open("bike_data.json", "r")
		p = file.read

		data = JSON.parse(p)
		return data
	end
end
