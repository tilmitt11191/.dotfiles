#!/usr/bin/env ruby
#
# calculate grid square code.

class CALC_GSC

 # calculate 3rd, 1/8 grid square code.
 def coordinate2_meshcode(lon, lat)
  # calc 1st grid square code
  lat15m = (lat * 1.5).floor
  mesh1 = lat15m * 100 + lon.floor - 100

  # calc 2nd grid square code
  latR = lat - lat15m / 1.5; lonR = lon - lon.floor
  lat2 = (latR / 5.0 * 60).floor; lon2 = (lonR / 7.5 * 60).floor
  mesh2 = lat2 * 10 + lon2

  # calc 3rd grid square code
  latR -= lat2 * 5.0 /60; lonR -= lon2 * 7.5 /60
  lat3 = (latR / 0.5 * 60).floor; lon3 = (lonR / 0.75 * 60).floor
  mesh3 = lat3 * 10 + lon3

  # calc 4th grid square code
  latR -= lat3 * 0.5 / 60; lonR -= lon3 * 0.75 / 60
  lat4 = (latR / (0.5/2) * 60).floor; lon4 = (lonR / (0.75/2) * 60).floor
  mesh4 = (lat4 * 2 + lon4 + 1).floor

  # calc 5th grid square code
  latR -= lat4 * (0.5/2) / 60; lonR -= lon4 * (0.75/2) / 60
  lat5 = (latR / (0.5/4) * 60).floor; lon5 = (lonR /(0.75/4) * 60).floor
  mesh5 = lat5 * 2 + lon5 + 1
    
  # calc 6th grid square code
  latR -= lat5 * (0.5/4) / 60; lonR -= lon5 * (0.75/4) / 60
  lat6 = (latR / (0.5/8) * 60).floor; lon6 = (lonR /(0.75/8) * 60).floor
  mesh6 = lat6 * 2 + lon6 + 1

  # 1/8 meshcode
  grid_square_code = mesh1*10000000 + mesh2*100000 + mesh3*1000 + mesh4*100 + mesh5*10 + mesh6
  # 3rd meshcode
  grid_square_code_3rd = mesh1*10000 + mesh2*100 + mesh3

  return grid_square_code
 end

 # calculate GPS coordinate from grid square code.
 def meshcode2_coordinate(gps_info)
  grid_square_code = gps_info.to_s
  
  # calc from 1st grid square code
  lat = grid_square_code[0..1].to_f / 1.5; lon = grid_square_code[2..3].to_f + 100

  # calc from 2nd grid square code
  latcode = grid_square_code[4].to_f; loncode = grid_square_code[5].to_f
  lat += latcode * 5 / 60; lon += loncode * 7.5 / 60

  # calc from 3rd grid square code 
  latcode = grid_square_code[6].to_f; loncode = grid_square_code[7].to_f
  lat += latcode * 0.5 / 60; lon += loncode * 0.75 / 60

  # calc from 4th grid square code 
  num = grid_square_code[8].to_f - 1; latcode = (num / 2).to_i
  loncode = (num - latcode * 2).to_f; 
  lat += latcode * 0.5 / 2 / 60; lon += loncode * 0.75 / 2 / 60

  # calc from 5th grid square code 
  num = grid_square_code[9].to_f - 1
  latcode = (num / 2).to_i; loncode = (num - latcode * 2).to_f
  lat += latcode * 0.5 / 4 / 60; lon += loncode * 0.75 / 4 / 60

  # calc from 6th grid square code 
  num = grid_square_code[10].to_f - 1
  latcode = (num / 2).to_i; loncode = (num - latcode * 2).to_f
  lat += latcode * 0.5 / 8 / 60; lon += loncode * 0.75 / 8 / 60

  mlat = 0.5 / 8; mlon = 0.75 / 8
   
  # left-down lat/ lon
  lat0 = lat; lon0 = lon
  # right-up lat/ lon
  lat1 = lat0 + mlat / 60; lon1 = lon0 + mlon / 60
    
  return lon0, lat0, lon1, lat1
 end
end

