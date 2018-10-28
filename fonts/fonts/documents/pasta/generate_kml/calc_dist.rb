#!/usr/bin/env ruby
#
# calculate distance between two points.

  # Vessel oval (former Japan land surveying system)
  BESSEL_R_X  = 6377397.155000 # Equator radius
  BESSEL_R_Y  = 6356079.000000 # Polar radius

  # GRS80 (world land surveying system)
  GRS80_R_X   = 6378137.000000 # Equator radius
  GRS80_R_Y   = 6356752.314140 # Polar radius

  # WGS84 (GPS)
  WGS84_R_X   = 6378137.000000 # Equator radius
  WGS84_R_Y   = 6356752.314245 # Polar radius
  
class CALC_DIST
 # calculate distance between a point.
 def dist2point(lon_1, lat_1, lon_2, lat_2)
  # set equator radius, a polar radius pro-designated land surveying.
  r_x = GRS80_R_X; r_y = GRS80_R_Y

  # calculate two points of longitude differences (radian)
  a_x = lon_1 * Math::PI / 180.0 - lon_2 * Math::PI / 180.0

  # calculate a difference of two points of latitude (radian)
  a_y = lat_1 * Math::PI / 180.0 - lat_2 * Math::PI / 180.0

  # calculate average of two points of latitude
  p = (lat_1 * Math::PI / 180.0 + lat_2 * Math::PI / 180.0) / 2.0

  # calculate an eccentricity
  e = Math::sqrt( (r_x ** 2 - r_y ** 2) / (r_x ** 2).to_f )

  # calculate denominator W of the meridian, east and west Line radius of curvature
  w = Math::sqrt(1 - (e ** 2) * ( (Math::sin(p) ) ** 2) )

  # calculate meridian radius of curvature
  m = r_x * (1 - e ** 2) / (w ** 3).to_f

  # calculate an east and west Line radius of curvature
  n = r_x / w.to_f

  # calculate distance
  d  = (a_y * m) ** 2
  d += (a_x * n * Math.cos(p) ) ** 2
  d  = Math::sqrt(d)

  # When I consider the earth to be a complete ball (spherical trigonometry)
  # D = R * acos( sin(y1) * sin(y2) + cos(y1) * cos(y2) * cos(x2-x1) )
  # But not use.
  d_1  = Math::sin(lat_1 * Math::PI / 180.0)
  d_1 *= Math::sin(lat_2 * Math::PI / 180.0)
  d_2  = Math::cos(lat_1 * Math::PI / 180.0)
  d_2 *= Math::cos(lat_2 * Math::PI / 180.0)
  d_2 *= Math::cos(lon_2 * Math::PI / 180.0 - lon_1 * Math::PI / 180.0)
  d_0  = r_x * Math::acos(d_1 + d_2).to_f

  return d # meter
 end
end

