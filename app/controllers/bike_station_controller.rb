require 'json'
require 'httparty'
require 'crack'
require 'open_uri_redirections'
class BikeStationController < ApplicationController
	def index
		@result = Hash.new
		@result_arr = []
		#get the location data
		@geodata = get_geo_info
		#puts @geodata
		if @geodata.class != @result.class
			@result = pack(@geodata, @result_arr)
		end
		#get the ubike data
		@data = get_data()
		c = bike_check(@data)
		if c != 0 && @geodata.class == @result.class
			@result = pack(c, @result_arr)
		elsif c == 0 && @geodata.class == @result.class
			@result_arr =  get_near_station(@data)
			@result = pack(c, @result_arr)
		end

		#the way of show
		render json: @result#{:info => @data["retVal"], :geo => @geodata}

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

	def get_near_station(station)
		dis_uri = "https://maps.googleapis.com/maps/api/distancematrix/json?"
		dis_origin = "origins=#{params["lat"]},#{params["lng"]}"
		api_key = "key=AIzaSyBaWsuNSpmcPIOzlfC9oR_R6HXvQ4qFyDo"
		dis_set = "mode=walking&units=metric"
		valid_station_arr = []
		station_arr = []
		station['retVal'].values.each do |bike_stat|
			lat_dif = bike_stat["lat"].to_f - params["lat"].to_f
			lng_dif = bike_stat["lng"].to_f - params["lng"].to_f
				if bike_stat["bemp"].to_i != 0 &&  lat_dif.abs < 0.01 && lng_dif.abs < 0.01
					dis_path = dis_uri + dis_origin + "&destinations=" + bike_stat["lat"] + "," + bike_stat["lng"] + "&" + dis_set + "&" + api_key
					distance_data = Crack::JSON.parse(HTTParty::get(dis_path).body)
					puts dis_path
					puts distance_data
					distance = distance_data["rows"][0]["elements"][0]["distance"]["value"] 
					valid_station_arr << {"sno" => bike_stat["sno"],"station" => bike_stat["sna"], "num_ubike" => bike_stat["sbi"], "dis" => distance}
			end
		end
		valid_station_arr = valid_station_arr.sort_by!{|h| h["dis"]}
		puts valid_station_arr
		h1 = {"station" => valid_station_arr[0]["station"], "num_bike" => valid_station_arr[0]["num_ubike"]}
		h2 = {"station" => valid_station_arr[1]["station"], "num_bike" => valid_station_arr[1]["num_ubike"]}
		return [h1, h2]
	end
	def error_handler
	end
end
