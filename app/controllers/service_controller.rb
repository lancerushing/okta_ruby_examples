# frozen_string_literal: true

## this controller demostrates a "service" style approach
class ServiceController < ApplicationController
  ActionController::Parameters.action_on_unpermitted_parameters = :raise

  def authorize
    redirect_to OktaAuthUri.call(session), allow_other_host: true
  end

  def callback
    id_token = OktaParseIdToken.call(**callback_params)
    ## do something interesting with the token...
    session[:email] = id_token['email']

    redirect_to '/hello/index'
  end

  def callback_params
    params.permit(:state, :code).to_hash.merge({ rails_session: session }).symbolize_keys
  end
end
