require 'json'
require 'httparty'
require 'crack'
require 'open_uri_redirections'
class BikeStationController < ApplicationController
	def index
		place_id = "place_id=ChIJi73bYWusQjQRgqQGXK260bw"
		map_uri = "https://maps.googleapis.com/maps/api/geocode/json?"
		api_key = "AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"
		full_path = "#{map_uri}latlng=#{params["lat"]},#{params["lng"]}&result_type=country|postal_code&key=#{api_key}"
		#puts full_path
		#get the ubike data
		@data = get_data()
		#get the location data
		geocode = HTTParty::get(full_path)
		@geodata = Crack::JSON.parse(geocode.body)



		#the way of show
		render json: {:info => @data["retVal"], :geo => @geodata}



		#here is test
		puts params["lat"]
		puts params["lng"]
		#@data["retVal"].each do |key, value|
		h1 =  @data["retVal"]["0001"]
		h2= @geodata["results"][0]["address_components"]
		puts h1
		puts h2
		#end
	end
private
	#@api_key = "AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDoyy"
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
