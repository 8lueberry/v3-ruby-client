require 'json'

module ZumataV3

  class ZumataError < StandardError; end
  class ClientConfigError < ZumataError; end

  class GeneralError < ZumataError; end
  class BadRequestError < ZumataError; end
  class InvalidApiKeyError < ZumataError; end
  class ForbiddenError < ZumataError; end
  class UnprocessableEntityError < ZumataError; end
  class NotFoundError < ZumataError; end
  class ServerError < ZumataError; end
  class SupplierError < ZumataError; end

  module ErrorClassifier
    def self.handle status_code, body
      json = nil
      begin
        json = JSON.parse(body)
      rescue JSON::ParserError
        raise GeneralError, body
      end
      classify_by_id(json)
    end

    def self.classify_by_id err
      case err["id"]
      when "bad_request"
        raise BadRequestError, err["message"]
      when "invalid_api_key"
        raise InvalidApiKeyError, err["message"]
      when "forbidden"
        raise ForbiddenError, err["message"]
      when "unprocessable_entity"
        raise UnprocessableEntityError, err["message"]
      when "not_found"
        raise NotFoundError, err["message"]
      when "server_error"
        raise ServerError, err["message"]
      when "supplier_error"
        raise SupplierError, err["message"]
      end
    end

  end

end
