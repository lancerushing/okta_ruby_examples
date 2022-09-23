# frozen_string_literal: true

class OktaAuth
  include ActiveModel::Model

  attr_accessor :rails_session, :state, :code, :id_token

  validates :rails_session, presence: true
  validates :state, presence: true
  validates :code, presence: true
  validate do |auth|
    %i[okta_state okta_code_verifier].each do |key|
      auth.errors.add :base, "missing key: #{key}" unless auth.rails_session.key?(key)
    end
  end
  validate :okta_code

  def redirect_uri
    @rails_session[:okta_state] = SecureRandom.hex(16)
    @rails_session[:okta_code_verifier] = SecureRandom.hex(50)
    authorization_endpoint
  end

  private

  def authorization_endpoint
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

  def challenge
    hash = Digest::SHA2.new(256).digest @rails_session[:okta_code_verifier]
    Base64.urlsafe_encode64(hash, padding: false)
  end

  def config
    Rails.application.config.x.okta
  end
end
