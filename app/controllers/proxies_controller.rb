require 'open-uri'
class ProxiesController < ApplicationController
  # don't need to do auth check here since it's just a proxy service for json
  skip_authorization_check

  GEOCODER_URL = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false"
  
  # forwards geocoding requests from json, so as not to run into same-origin policy
  def geocoder
    begin
      render(:json => open("#{GEOCODER_URL}&#{request.query_string}"){|f| f.read})
    rescue SocketError
      render(:text => $!.to_s, :status => 500)
    end
  end
end