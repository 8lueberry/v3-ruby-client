require 'httparty'
require 'time'
require 'awesome_print'
require 'json'

module ZumataV3
  class HotelClient
  	include HTTParty

    def initialize opts={}
      raise ZumataV3::ClientConfigError.new("No API URL configured or API key provided") if ZumataV3.configuration.nil?
      raise ZumataV3::ClientConfigError.new("No API URL configured") if ["",nil].include?(ZumataV3.configuration.api_url)
      raise ZumataV3::ClientConfigError.new("No API key provided") if ["",nil].include?(ZumataV3.configuration.api_key)
      @api_url = ZumataV3.configuration.api_url
      @api_key = ZumataV3.configuration.api_key
    end

    # GET /search
  	def search_by_destination_id destination_id, opts={}

      q = { destination_id: destination_id,
            room_count: opts[:room_count] || 1,
            adult_count: opts[:adult_count] || 2,
            currency: opts[:currency] || "USD" }

      q[:child_count] = opts[:child_count] if opts[:child_count]
      q[:source_market] = opts[:source_market] if opts[:source_market]

      q[:check_in_date]  = opts[:check_in_date]
      q[:check_out_date] = opts[:check_out_date]

      res = self.class.get("#{@api_url}/search", query: q, headers: {"X-Api-Key" => @api_key}).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: q, code: res.code.to_i, body: res.body)
    end

  end
end