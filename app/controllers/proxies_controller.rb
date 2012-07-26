class ProxiesController < ApplicationController
  require 'open-uri'
  GEOCODER_URL = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false"
  def geocoder
    begin
      render(:json => open("#{GEOCODER_URL}&#{request.query_string}"){|f| f.read})
    rescue SocketError
      render(:text => $!.to_s, :status => 500)
    end
  end
end