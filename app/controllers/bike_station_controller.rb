require 'json'
require 'httparty'
require 'crack'
require 'open_uri_redirections'
class BikeStationController < ApplicationController
	def index
		#get the ubike data
		@data = get_data()
		#get the location data
		@geodata = get_geo_info
		puts @geodata
		if @geodata.class != "Hash"
			result = pack(@geodata, [])
		end
	
		c = bike_check(@data)

		#the way of show
		render json: result#{:info => @data["retVal"], :geo => @geodata}

		#here is test
		puts params["lat"]
		puts params["lng"]
		#@data["retVal"].each do |key, value|
		h1 =  @data["retVal"]["0001"]
		#h2= @geodata["results"][0]["address_components"]
		puts h1
		#puts h2
		puts c
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
		#puts data.class
		#data's type is Hash
		return data
	end
		
	def get_geo_info
		la = params["lat"].to_f
		ln = params["lng"].to_f
		puts la
		puts ln
		if la > 90.0 || la < -90.0 || ln > 180.0 || ln < -180.0
			message = "Invalid latitude and longtitude"
			puts message
			return -1
		end
	
		place_id = "place_id=ChIJi73bYWusQjQRgqQGXK260bw"
		map_uri = "https://maps.googleapis.com/maps/api/geocode/json?"
		api_key = "AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"
		full_path = "#{map_uri}latlng=#{params["lat"]},#{params["lng"]}&result_type=country|postal_code&key=#{api_key}"
		data = Crack::JSON.parse(HTTParty::get(full_path).body)
		puts "Hello"
		if data["results"] == []
			puts "The location is not Taipei"
			return -2
		end
		for x in data["results"][0]["address_components"]
			if x["types"][0] == "administrative_area_level_1"
				h = x
			end
		end
		
		if h["long_name"] != "Taipei City"
			message = "The location is not in Taipei"
			puts message
			return -2
		else
			return data
		end
	end

	def bike_check(data)
		f = 1
		 data_arr = data['retVal'].values
		 data_arr.each do |bike|
			 if bike["bemp"].to_i != 0
				 return 0
			 end
		 end
		 return 1
		 #puts data_arr.class
	end

	def pack(code, data)
		h = {"code"=> code, "result"=>data}
	end

	def error_handler
	end
end
