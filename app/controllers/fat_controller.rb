# frozen_string_literal: true

require 'jwt'
require 'pry'

# A "fat" controller for okta authentication
# all your authentication in one place
class FatController < ApplicationController
  include HTTParty

  ActionController::Parameters.action_on_unpermitted_parameters = :raise

  def authorize
    session[:okta_state] = SecureRandom.hex(16)
    session[:okta_code_verifier] = SecureRandom.hex(50)

    hash = Digest::SHA2.new(256).digest session[:okta_code_verifier]
    challenge = Base64.urlsafe_encode64(hash, padding: false)

    authorization_uri = "#{config.issuer}/v1/authorize?" + {
      'response_type' => 'code',
      'state' => session[:okta_state],
      'scope' => 'openid profile email',
      'client_id' => config.client_id,
      'redirect_uri' => "#{config.redirect_uri}/fat/callback",
      'code_challenge' => challenge,
      'code_challenge_method' => 'S256'
    }.to_query

    redirect_to authorization_uri, allow_other_host: true
  end

  def callback
    raise BadStateError unless callback_params[:state] == session.delete(:okta_state)

    http_response = HTTParty.post(
      "#{config.issuer}/v1/token",
      body: {
        'code' => callback_params[:code],
        'client_id' => config.client_id,
        'grant_type' => 'authorization_code',
        'redirect_uri' => "#{config.redirect_uri}/fat/callback",
        'code_verifier' => session.delete(:okta_code_verifier),
        'client_secret' => config.client_secret
      }
    )

    response = JSON.parse(http_response.body)

    raise TokenApiError, "#{response['error']}: #{response['error_description']}" unless response['error'].blank?
    raise MissingTokenError, 'access_token missing' if response['access_token'].blank?
    raise MissingTokenError, 'id_token missing' if response['id_token'].blank?

    access_token = verify(response['access_token'], 'api://default')
    id_token = verify(response['id_token'], access_token['cid'])

    ## do something interesting with the tokens...
    session[:email] = id_token['email']

    redirect_to '/hello/index'
  end

  private

  def config
    Rails.application.config.x.okta
  end

  def callback_params
    params.permit(:state, :code)
  end

  def verify(token, aud)
    JWT.decode(
      token,
      nil,
      true,
      jwks:,
      algorithm: 'RS256',
      verify_iss: true,
      iss: config.issuer,
      verify_aud: true,
      aud:,
      verify_sub: true,
      verify_iat: true,
      verify_expiration: true,
      verify_not_before: true,
      leway: 60
    ).first
  rescue JWT::DecodeError => e
    raise e, token
  end

  def jwks
    wellknown_uri = "#{config.issuer}/.well-known/openid-configuration"
    jwks_uri = JSON.parse(HTTParty.get(wellknown_uri).body)['jwks_uri']
    JSON.parse(HTTParty.get(jwks_uri).body)
  end

  class BadStateError < StandardError; end
  class TokenApiError < StandardError; end
  class MissingTokenError < StandardError; end
end
