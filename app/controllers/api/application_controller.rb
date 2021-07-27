# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::API
    AUTHORIZATION_HEADER_KEY = 'authorization'

    # noinspection RubyResolve
    before_action :authenticate_request
    attr_reader :current_user

    private

    def authenticate_request
      headers = request.headers

      token = headers[AUTHORIZATION_HEADER_KEY]

      return not_authorized unless token.present?

      @current_user = User.find_by_jwt_token token

      not_authorized unless @current_user.present?
    end

    def not_authorized
      render_json({}, :unauthorized)
    end

    def invalid_messages(errors)
      render_json errors.to_hash, :unprocessable_entity
    end

    def render_error(message, status: :unprocessable_entity)
      render_json({ error: message }, status)
    end

    def render_json(data = {}, status = :ok)
      render json: data,
             status: status
    end

    # Needs to be a Kaminari Paginator
    def render_pagination(results, &block)
      out_of_bounds = results.total_count.zero? || results.last_page?

      response = {
        data: results.map(&block),
        total: results.total_count,
        page: results.current_page,
        next_page: results.next_page,
        prev_page: results.prev_page,
        needs_load_more: !out_of_bounds
      }

      render_json response
    end
  end
end
