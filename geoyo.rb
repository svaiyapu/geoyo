#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'redis'

configure do
    @@redis = nil
    services = ENV['VCAP_SERVICES']
    if services then
        services = JSON.parse(services)
        redis_key = services.keys.select { |svc| svc =~ /redis/i }.first
        if redis_key then
            redis = services[redis_key].first['credentials']
            redis_conf = {:host => redis['hostname'], :port => redis['port'], :password => redis['password']}
            @@redis = Redis.new redis_conf
        end
    end
end

helpers do
    def geocode(address)
        key = address.downcase.gsub(/\s+/,' ')
        if @@redis then
            value = @@redis.get(key)
            if value then
                return JSON.parse(value), nil
            end
        end
        resp = Net::HTTP.get_response(URI.parse("http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=#{URI.escape(address)}"))
        error = case resp
                    when Net::HTTPSuccess then nil
                    else "Geo-coding failed.  Please verify address"
                end
        @@redis.set(key, resp.body) if @@redis
        return JSON.parse(resp.body), error
    end
end
    
get '/' do
    erb :index
end

post '/' do
    @address = params[:address]
    @body, @error = geocode(@address)
    if @body['status'] != 'OK' then
        @error = "Geo-coding failed.  Please verify address"
    end
    if @error then
        @body = nil
    end
    if @body != nil then
        @lat = @body['results'][0]['geometry']['location']['lat']
        @lng = @body['results'][0]['geometry']['location']['lng']
        @full_address = @body['results'][0]['formatted_address']
    end
    erb :index
end
