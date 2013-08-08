class Oauth::ClientAppController < ApplicationController
  before_filter :require_operator
  
  def new
    @client_app = Oauth::ClientApplication.new
  end
  
  def create
    @client_app = Oauth::ClientApplication.find_by_name(params[:oauth_client_application][:name])
    @client_app ||= Oauth::ClientApplication.create_with_name(params[:oauth_client_application][:name])
    if @client_app.save
      # do nothing
    else
      render :new
    end
  end
  
  def index
    @client_apps = Oauth::ClientApplication.all
  end
  
  def destroy
    @client_app = Oauth::ClientApplication.find(params[:id])
    @client_app.destroy
    redirect_to oauth_client_applications_url
  end
end