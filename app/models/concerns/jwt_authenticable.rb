# frozen_string_literal: true

module JwtAuthenticable
  extend ActiveSupport::Concern

  included do
    def self.find_by_jwt_token(token)
      return unless token.include?('Bearer ')
      token = token.split(' ').last
      data = JsonWebToken.decode(token)

      return unless data

      id = data[:id]

      find(id)
    end
  end

  def generate_jwt_token
    payload = { id: id }
    JsonWebToken.encode payload
  end
end
