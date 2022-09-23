# frozen_string_literal: true

## this controller demostrates a "service" style approach
class ModelController < ApplicationController
  ActionController::Parameters.action_on_unpermitted_parameters = :raise

  def authorize
    redirect_to okta_auth.redirect_uri, allow_other_host: true
  end

  def callback
    if okta_auth.valid?
      ## do something interesting with the token...
      session[:email] = okta_auth.id_token['email']

      redirect_to '/hello/index'
    else
      render html: okta_auth.errors.full_messages.to_sentence, status: :bad_request
    end
  end

  private

  def okta_auth
    @okta_auth ||= OktaAuth.new(auth_params)
  end

  def auth_params
    params.permit(:state, :code).to_hash.merge({ rails_session: session }).symbolize_keys
  end
end
