#!/usr/bin/env ruby
#
# encode/ decode locapoint

class CALC_LOCAPO
 # encode locapoint from GPS coordinates.
 def enc_locapo(lon, lat)
  lonlat_array = Array.new

  longitude_step = (lon + 180) / 360 * 45697600
  latitude_step = (lat + 90) / 180 * 45697600
  
  lonlat_array = [
    latitude_step / 1757600 % 26 + 65,
    latitude_step / 67600 % 26 + 65,
    latitude_step / 6760 % 10 + 48,
    46,
    longitude_step / 1757600 % 26 + 65,
    longitude_step / 67600 % 26 + 65,
    longitude_step / 6760 % 10 + 48,
    46,
    latitude_step / 260 % 26 + 65,
    latitude_step / 10 % 26 + 65,
    latitude_step / 1 % 10 + 48,
    46,
    longitude_step / 260 % 26 + 65,
    longitude_step / 10 % 26 + 65,
    longitude_step / 1 % 10 + 48
  ]  

  locapo = lonlat_array.pack("U*")

  return locapo
 end

 # decode GPS coordinates from locapoint.
 def dec_locapo(locapo)
  latitude = (
    ((locapo[0].unpack("U")[0] - 65) * 1757600 \
    + (locapo[1].unpack("U")[0] - 65) * 67600 \
    + (locapo[2].unpack("U")[0] - 48) * 6760 \
    + (locapo[8].unpack("U")[0] - 65) * 260 \
    + (locapo[9].unpack("U")[0] - 65) * 10 \
    + (locapo[10].unpack("U")[0] - 48) * 1  ) \
    * 180).to_f / 45697600 - 90

  longitude = (
    ((locapo[4].unpack("U*")[0] - 65) * 1757600 \
    + (locapo[5].unpack("U*")[0] - 65) * 67600 \
    + (locapo[6].unpack("U*")[0] - 48) * 6760 \
    + (locapo[12].unpack("U*")[0] - 65) * 260 \
    + (locapo[13].unpack("U*")[0] - 65) * 10 \
    + (locapo[14].unpack("U*")[0] - 48) * 1 ) \
    * 360).to_f / 45697600 - 180

  return longitude, latitude
 end
end

