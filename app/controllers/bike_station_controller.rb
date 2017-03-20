require 'json'
require 'httparty'
require 'open_uri_redirections'
class BikeStationController < ApplicationController
	def index
		@result = Hash.new
		@result_arr = []
		@geodata = get_geo_info									#get the location data
		if @geodata.class != @result.class || @geodata == -3  	#input errors and systems error
			@result = pack(@geodata, @result_arr)				#pack error code and []
		end
		@data = get_data()										#get the bike_station data
		c = bike_check(@data)									#check staition is empty?
		if c != 0 && @geodata.class == @result.class			#station is empty
			@result = pack(c, @result_arr)						
		elsif c== -3											#system error
			@result = pack(c, @result_arr)
		elsif c == 0 && @geodata.class == @result.class			#OK
			@result_arr =  get_near_station(@data)				#get two nearest station
			@result = pack(c, @result_arr)
		end

		#the way of show
		render json: @result									#render with json
	end

private
	def get_data
		uri = "http://data.taipei/youbike"
		File.open("bike_data.json", "wb") do |file|				#download data as bike_data.json
			begin
				file.write open(uri, :allow_redirections => :safe).read 
			rescue StandardError => e
				return -3										#download fail => return -3
			end

		end

		file = File.open("bike_data.json", "r")					#read file
		p = file.read

		data = JSON.parse(p)									#turn JSON to HASH
		return data
	end
		
	def get_geo_info
		la = params["lat"].to_f
		ln = params["lng"].to_f
		if la > 90.0 || la < -90.0 || ln > 180.0 || ln < -180.0	#check the validation of latitude and longitude and return error code:-1
			message = "Invalid latitude and longtitude"
			puts message
			return -1
		end
	
		map_uri = "https://maps.googleapis.com/maps/api/geocode/json?"	#API main uri
		api_key = "AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"				#API KEY
		full_path = "#{map_uri}latlng=#{params["lat"]},#{params["lng"]}&result_type=country|postal_code&key=#{api_key}"

		begin
		get_location = HTTParty::get(full_path)							#get the geo-data of params["lat", "lng"]
		rescue HTTParty::Error => e										#HTTP error => return -3
			return -3
		rescue StandardError => e										#system error
			return -3
		end

		data = JSON.parse(get_location.body)							#turn geo-data to HASH
		if data["results"] == []										#empty data => no data about this location
			puts "The location is not in Taipei"
			return -2
		end
		for x in data["results"][0]["address_components"]				#find the key-value is admini_level1- City
			if x["types"][0] == "administrative_area_level_1"
				h = x
			end
		end
		
		if h["long_name"] != "Taipei City"								#check the location is in Taipei City?
			message = "The location is not in Taipei"
			puts message
			return -2
		else
			return data
		end
	end

	def bike_check(data)												#check the station is empty by checking the station's bemp
		f = 1
		 data_arr = data['retVal'].values
		 data_arr.each do |bike|
			 if bike["bemp"].to_i != 0
				 return 0
			 end
		 end
		 return 1
	end

	def pack(code, data)
		h = {"code"=> code, "result"=>data}
	end

	def get_near_station(station)												#find the two nearest station with bikes from the appointed location
		dis_uri = "https://maps.googleapis.com/maps/api/distancematrix/json?"	#API URI
		dis_origin = "origins=#{params["lat"]},#{params["lng"]}"				#origin and destination
		api_key = "key=AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"					#API key
		dis_set = "mode=walking&units=metric"									#API setting with walking mode and unit is m/km
		valid_station_arr = []
		station['retVal'].values.each do |bike_stat|
			lat_dif = bike_stat["lat"].to_f - params["lat"].to_f
			lng_dif = bike_stat["lng"].to_f - params["lng"].to_f
				if bike_stat["bemp"].to_i != 0 &&  lat_dif.abs < 0.01 && lng_dif.abs < 0.01	#select the station from the location in area with difference of 1 deg lat and lng
					dis_path = dis_uri + dis_origin + "&destinations=" + bike_stat["lat"] + "," + bike_stat["lng"] + "&" + dis_set + "&" + api_key
					
					begin
					get_distance = HTTParty::get(dis_path)i						#for each selected station get its path distance-data from location
					rescue HTTParty::Error => e									#handlde system error
						return -3
					rescue StandardError => e
						return -3
					end
					distance_data = JSON.parse(get_distance.body)
					distance = distance_data["rows"][0]["elements"][0]["distance"]["value"]	#get distance
					valid_station_arr << {"sno" => bike_stat["sno"],"station" => bike_stat["sna"], "num_ubike" => bike_stat["sbi"], "dis" => distance}	#store distance and other info in hash arr
			end
		end
		valid_station_arr = valid_station_arr.sort_by!{|h| h["dis"]}			#sort the hash array by distance from near to far
		h1 = {"station" => valid_station_arr[0]["station"], "num_bike" => valid_station_arr[0]["num_ubike"]}	#get two stantion data with re-pack to hash
		h2 = {"station" => valid_station_arr[1]["station"], "num_bike" => valid_station_arr[1]["num_ubike"]}
		return [h1, h2]
	end
end
