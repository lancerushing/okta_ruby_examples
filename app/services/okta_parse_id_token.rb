# frozen_string_literal: true

## provide okta token interface
class OktaParseIdToken < ApplicationService
  def initialize(rails_session:, code:, state:)
    @rails_session = rails_session
    @code = code
    @state = state
  end

  def call
    raise BadStateError unless @state == @rails_session.delete(:okta_state)

    resp = token_response
    raise TokenApiError, "#{resp['error']}: #{resp['error_description']}" unless resp['error'].blank?
    raise MissingTokenError, 'access_token missing' if resp['access_token'].blank?
    raise MissingTokenError, 'id_token missing' if resp['id_token'].blank?

    access_token = verify(resp['access_token'], 'api://default')
    verify(resp['id_token'], access_token['cid'])
  end

  private

  def token_response
    JSON.parse(HTTParty.post(
      "#{config.issuer}/v1/token",
      body: {
        'code' => @code,
        'client_id' => config.client_id,
        'grant_type' => 'authorization_code',
        'redirect_uri' => "#{config.redirect_uri}/service/callback",
        'code_verifier' => @rails_session.delete(:okta_code_verifier),
        'client_secret' => config.client_secret
      }
    ).body)
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
