# frozen_string_literal: true

## provide okta token interface
class OktaAuthUri < ApplicationService
  def initialize(rails_session)
    @rails_session = rails_session
  end

  def call
    @rails_session[:okta_state] = SecureRandom.hex(16)
    @rails_session[:okta_code_verifier] = SecureRandom.hex(50)

    "#{config.issuer}/v1/authorize?" + {
      'response_type' => 'code',
      'state' => @rails_session[:okta_state],
      'scope' => 'openid profile email',
      'client_id' => config.client_id,
      'redirect_uri' => "#{config.redirect_uri}/service/callback",
      'code_challenge' => challenge,
      'code_challenge_method' => 'S256'
    }.to_query
  end

  private

  def challenge
    hash = Digest::SHA2.new(256).digest @rails_session[:okta_code_verifier]
    Base64.urlsafe_encode64(hash, padding: false)
  end
end
