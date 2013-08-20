class Oauth::AuthController < ApplicationController
  before_filter      :opro_authenticate_user!,    :except => [:access_token, :account_details]
  skip_before_filter :verify_authenticity_token,  :only => [:access_token, :user]
  before_filter      :ask_user!,                  :only => :authorize

  before_filter      :allow_oauth,                :only => [:account_details]

  def new
    @redirect_uri = params[:redirect_uri]
    @client_app   = Oauth::ClientApplication.find_by_app_id(params[:client_id])
    @scopes       = scope_from_params(params)
  end

  def authorize
    application  =   Oauth::ClientApplication.find_by_app_id(params[:client_id])
    permissions  =   params[:permissions]
    access_grant =   Oauth::AccessGrant.where( :user_id => current_user.id, :application_id => application.id).first
    access_grant ||= Oauth::AccessGrant.create(:user => current_user,       :application => application)
    access_grant.update_attributes(:permissions => permissions) if access_grant.permissions != permissions
    unless params[:redirect_uri].nil?
      redirect_to access_grant.redirect_uri_for(params[:redirect_uri])
    else
      render :text => 'missing redirect_uri parameter'
    end
  end

  def access_token    
    if params[:code].nil?
      render :json => {:error => "Missing code param"}, :status => 400
      return
    end
    
    application = Oauth::ClientApplication.authenticate(params[:client_id], params[:client_secret])

    if application.nil?
      render :json => {:error => "Could not find application"}, :status => 400
      return
    end

    access_grant = Oauth::AccessGrant.authenticate(params[:code], application.id)

    if access_grant.nil?
      render :json => {:error => "Could not authenticate access code"}, :status => 400
      return
    end

    access_grant.start_expiry_period!
    render :json => {
      :id => access_grant.user_id,
      :access_token => access_grant.access_token,
      :refresh_token => access_grant.refresh_token,
      :expires_in => access_grant.access_token_expires_at
    }
  end

  # When a user is sent to authorize an application they must first accept the authorization
  # if they've already authed the app, they skip this section
  def ask_user!
    # if user is not authenticated return false
    if current_user.nil?
      return false
    end
    
    if params[:client_id].nil?
      render :json => { :error => "Missing client_id parameter" }, :status => 400
      return
    end
    
    @client_app = Oauth::ClientApplication.find_by_app_id(params[:client_id])
    
    if @client_app.nil?
      render :json => { :error => "Application not found" }, :status => 404
      return
    end
    
    if request.method != 'GET'
      return true
    elsif user_granted_access_before?(current_user, params)
      # Re-Authorize the application, do not ask the user
      return true
    elsif user_authorizes_the_request?(request)
      # Authorize the application, do not ask the user
      return true
    else
      # if the request did not come from a form within the application, render the user form
      @redirect_uri ||= params[:redirect_uri]
      @client_app   ||= Oauth::ClientApplication.find_by_app_id(params[:client_id])
      redirect_to oauth_new_path({ :client_id => @client_app.app_id, :redirect_uri => @redirect_uri })
    end
  end
  
  def account_details
    account_details = {
      :id => current_account.id,
      :username => current_account.username,
      :email => current_account.email,
      :first_name => current_account.given_name,
      :last_name => current_account.surname,
      :birth_date => current_account.birth_date,
    }
    
    render :json => account_details.to_json
  end

  protected

  def allow_oauth?
    @use_oauth ||= false
    oauth_user
  end

  # returns boolean if oauth request
  def valid_oauth?
    oauth? && oauth_user.present? && oauth_client_has_permissions?
  end

  def disallow_oauth
    @use_oauth = false
  end

  def allow_oauth
    if oauth_access_grant.nil?
      render :json => { 'error' => 'invalid access token' }, :status => 400
    end
    @use_oauth = true
  end

  def oauth?
    allow_oauth? && params[:access_token].present?
  end

  def oauth_access_grant
    @oauth_access_grant ||= Oauth::AccessGrant.find_for_token(params[:access_token])
  end

  def oauth_client_app
    @oauth_client_app   ||= oauth_access_grant.client_application
  end

  def oauth_user
    @oauth_user         ||= oauth_access_grant.user rescue nil
  end

  def oauth_auth!
    ::Opro.login(self, oauth_user)  if valid_oauth?
    yield
    ::Opro.logout(self, oauth_user) if valid_oauth?
  end

  private
  
  def user_granted_access_before?(user, params)
    @client_app ||= Oauth::ClientApplication.find_by_app_id(params[:client_id])
    Oauth::AccessGrant.where(:application_id => @client_app.id, :user_id => user.id).present?
  end

  def scope_from_params(params)
    requested_scope = (params[:scope]||[]).map(&:downcase)
    default_scope   = ::Opro.request_permissions.map(&:to_s).map(&:downcase)
    return default_scope if requested_scope.blank?
    requested_scope & default_scope
  end

  # We're verifying that a post was made from our own site, indicating a user confirmed via form
  def user_authorizes_the_request?(request)
    request.post? && referrer_is_self?(request)
  end

  # Ensures that the referrer is also the current host, to prevent spoofing
  def referrer_is_self?(request)
    return false if request.referrer.blank?
    referrer_host = URI.parse(request.referrer).host
    self_host     = URI.parse(request.url).host
    referrer_host == self_host
  end

end