# frozen_string_literal: true

class Validator < ActiveModel::Validator
  def validate(auth)
    resp = token_response(auth)

    return unless resp

    begin
      access_token = verify(resp['access_token'], 'api://default')
      id_token = verify(resp['id_token'], access_token['cid'])

      auth.id_token = id_token ## Crufy to set is??
    rescue JWT::DecodeError => e
      login.errors.add :base, "token did not decode #{e.message}"
    rescue JWT::VerificationError => e
      login.errors.add :base, "token did not verif #{e.message}"
    end
  end

  private

  def token_response(auth)
    response = JSON.parse(HTTParty.post(
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

    unless response['error'].blank?
      auth.errors.add :base,
                      "token endpoint returned an erorr: #{response['error']}: #{response['error_description']}"
      return nil
    end
    if response['access_token'].blank?
      auth.errors.add :base,
                      'token endpoint did not return an access token'
      return nil
    end

    response
  end

  def config
    Rails.application.config.x.okta
  end
end
