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

      headers = init_headers opts
      res = self.class.get("#{@api_url}/search", query: q, headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: q, code: res.code.to_i, body: res.body)
    end

    # POST /pre_book
    def prebook search, package, config, opts={}

      req = { search: search,
            package: package,
            config: config }

      headers = init_headers opts
      res = self.class.post("#{@api_url}/pre_book", body: req.to_json, headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: req, code: res.code.to_i, body: res.body)
    end

    # GET /pre_book
    def get_prebook pre_book_id, opts={}
      headers = init_headers opts
      res = self.class.get("#{@api_url}/pre_book/#{pre_book_id}", headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: {pre_book_id: pre_book_id}, code: res.code.to_i, body: res.body)
    end

    # POST /book
    def book_by_credit guest, pre_book_id, opts={}

      req = { guest: guest,
              payment: {
                :type => "credit"
              },
              pre_book_id: pre_book_id }

      req[:affiliate_key] = opts[:affiliate_key] if opts[:affiliate_key]

      headers = init_headers opts
      res = self.class.post("#{@api_url}/book", body: req.to_json, headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: req, code: res.code.to_i, body: res.body)
    end

    # GET /book/status
    def get_book reference, opts={}
      headers = init_headers opts
      res = self.class.get("#{@api_url}/book/status/#{reference}", headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: {reference: reference}, code: res.code.to_i, body: res.body)
    end

    # POST /cancel
    def cancel reference, opts={}

      req = {
        reference: reference
      }

      headers = init_headers opts
      res = self.class.post("#{@api_url}/cancel", body: req.to_json, headers: headers).response
      ZumataV3::ErrorClassifier.handle(res.code.to_i, res.body) unless [200,201].include?(res.code.to_i)
      ZumataV3::GenericResponse.new(context: {reference: reference}, code: res.code.to_i, body: res.body)
    end

    private

    def init_headers opts={}
      headers = {"X-Api-Key" => @api_key}
      if opts[:headers] != nil && opts[:headers].class == Hash
        headers = headers.merge(opts[:headers])
      end
    end

  end
end
