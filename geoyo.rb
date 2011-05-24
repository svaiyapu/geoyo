#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'net/http'
require 'uri'
require 'json'

helpers do
    def geocode(address)
        resp = Net::HTTP.get_response(URI.parse("http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{URI.escape(address)}"))
        error = case resp
                    when Net::HTTPSuccess then nil
                    else "Geo-coding failed.  Please verify address"
                end
        return JSON.parse(resp.body), error
    end
end
    
get '/' do
    erb :index
end

post '/' do
    @address = params[:address]
    @body, @error = geocode(@address)
    erb :index
end
