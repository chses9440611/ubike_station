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
		elsif c == 0 && @geodata.class == @result.class
			@result_arr =  get_near_station(@data)
			@result = pack(c, @result_arr)
		end

		#the way of show
		render json: @result
	end

private
	def get_data
		#dataa uri
		uri = "http://data.taipei/youbike"
		File.open("bike_data.json", "wb") do |file|
			#download data as bike_data.json
			begin
				file.write open(uri, :allow_redirections => :safe).read
			rescue StandardError => e
				return -3
			end

		end

		file = File.open("bike_data.json", "r")
		p = file.read

		data = JSON.parse(p)
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

		begin
		get_location = HTTParty::get(full_path)
		rescue HTTParty::Error => e
			return -3
		rescue StandardError => e
			return -3
		end

		data = JSON.parse(get_location.body)
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
	end

	def pack(code, data)
		h = {"code"=> code, "result"=>data}
	end

	def get_near_station(station)
		dis_uri = "https://maps.googleapis.com/maps/api/distancematrix/json?"
		dis_origin = "origins=#{params["lat"]},#{params["lng"]}"
		api_key = "key=AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"
		dis_set = "mode=walking&units=metric"
		valid_station_arr = []
		station['retVal'].values.each do |bike_stat|
			lat_dif = bike_stat["lat"].to_f - params["lat"].to_f
			lng_dif = bike_stat["lng"].to_f - params["lng"].to_f
				if bike_stat["bemp"].to_i != 0 &&  lat_dif.abs < 0.01 && lng_dif.abs < 0.01
					dis_path = dis_uri + dis_origin + "&destinations=" + bike_stat["lat"] + "," + bike_stat["lng"] + "&" + dis_set + "&" + api_key
					
					begin
					get_distance = HTTParty::get(dis_path)
					rescue HTTParty::Error => e
						return -3
					rescue StandardError => e
						return -3
					end
					distance_data = JSON.parse(get_distance.body)
					distance = distance_data["rows"][0]["elements"][0]["distance"]["value"] 
					valid_station_arr << {"sno" => bike_stat["sno"],"station" => bike_stat["sna"], "num_ubike" => bike_stat["sbi"], "dis" => distance}
			end
		end
		valid_station_arr = valid_station_arr.sort_by!{|h| h["dis"]}
		h1 = {"station" => valid_station_arr[0]["station"], "num_bike" => valid_station_arr[0]["num_ubike"]}
		h2 = {"station" => valid_station_arr[1]["station"], "num_bike" => valid_station_arr[1]["num_ubike"]}
		return [h1, h2]
	end
end
