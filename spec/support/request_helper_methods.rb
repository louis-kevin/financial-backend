module RequestHelperMethods
  def authorization_header
    token = @user.generate_jwt_token
    { authorization: "Bearer #{token}" }
  end

  def get_with_token(url, params = {}, headers = {})
    get url, params: params, headers: authorization_header.merge(headers)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end

  def post_with_token(url, params, headers = {})
    post url, params: params, headers: authorization_header.merge(headers)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end

  def put_with_token(url, params, headers = {})
    put url, params: params, headers: authorization_header.merge(headers)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end

  def delete_with_token(url, headers = {})
    delete url, headers: authorization_header.merge(headers)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end
end
