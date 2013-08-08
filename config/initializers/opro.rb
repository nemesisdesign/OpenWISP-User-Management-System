Opro.setup do |config|
  ## Configure the auth_strategy or use set :login_method, :logout_method, & :authenticate_user_method
  config.login_method { |controller, current_account| AccountSession.create(current_account) }
  
  config.logout_method do |controller, current_account|
    session = AccountSession.find
    session.destroy
  end
  
  config.authenticate_user_method { |controller| controller.require_account }

  ## Add or remove application permissions
  # Read permission is turned on by default (any request with [GET])
  # Write permission is requestable by default (any request other than [GET])
  # Custom permissions can be configured by adding them to the request_permissions Array and configuring require_oauth_permissions in the controller
  #config.request_permissions = [:write]
end