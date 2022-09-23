class HelloController < ApplicationController
  
  helper_method :current_email

 
  def index
   
  end

  def current_email
    session[:email]
  end

  
end
