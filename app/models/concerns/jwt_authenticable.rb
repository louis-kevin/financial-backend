module JwtAuthenticable
  extend ActiveSupport::Concern

  included do
    def self.find_by_jwt_token(token)
      token.gsub! 'Bearer ', ''
      data = JsonWebToken.decode(token)

      id = data[:id]

      self.find(id)
    end
  end


  def generate_jwt_token
    payload = { id: id }
    JsonWebToken.encode payload
  end
end