# frozen_string_literal: true

class HelloController < ApplicationController
  helper_method :current_email

  def index; end

  def signout
    session.delete(:email)
    redirect_to '#index'
  end

  def current_email
    session[:email]
  end
end
