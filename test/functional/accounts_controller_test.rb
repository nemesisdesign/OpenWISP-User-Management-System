require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  
  setup :activate_authlogic
  
  test "create_new" do
    # disable captcha
    Configuration.set('captcha_enabled', 'false')
    
    CONFIG['birth_date'] = false
    CONFIG['address'] = false
    CONFIG['zip'] = false
    CONFIG['city'] = false
    
    user_count = User.count
    
    account_data = {
      :mobile_prefix => '39',
      :mobile_suffix => '3664253801',
      :mobile_prefix_confirmation => '39',
      :mobile_suffix_confirmation => '3664253801',
      :given_name => 'Pinco',
      :surname => 'Pallo',
      :username => '393664253801',
      :email => 'pincopallo@test.com',
      :email_confirmation => 'pincopallo@test.com',
      :password => 'federico3',
      :password_confirmation => 'federico3',
      :privacy_acceptance => true,
      :eula_acceptance => true,
      :state => 'Italy',
      :city => '',
      :zip => '',
      :address => '',
      :birth_date => ''
    }
    post :create, { :account => account_data }
    
    # ensure user is created
    assert_equal user_count+1, User.count
    # ensure user is redirected to account path
    assert_redirected_to account_path
    
    # ensure parameters are saved correctly
    user = User.last
    assert_equal '39', user.mobile_prefix
    assert_equal '3664253801', user.mobile_suffix
    assert_equal '393664253801', user.mobile_phone
    assert_equal 'pincopallo@test.com', user.email
    assert_equal 'Pinco', user.given_name
    assert_equal 'Pallo', user.surname
  end
  
  test "index accessible" do
    get :instructions
    assert_response :success
    
    get :instructions, { :locale => :en }
    assert_response :success
    
    get :instructions, { :locale => :es }
    assert_response :success
  end
  
  test "account registration should be accessible" do
    get :new
    assert_response :success
  end
  
  test "account page restricted to logged in users" do
    # unauthenticated user will be redirected to login
    get :show
    assert_redirected_to new_account_session_path
    # authenticated user should succeed
    # can't manage to get this to work...
    #AccountSession.create(users(:one))
    #get :show
    #puts response
    #assert_redirected_to account_path
  end
  
  test "gestpay_verify_credit_card should redirect to login" do
    post :gestpay_verify_credit_card
    assert_redirected_to new_account_session_path
  end
  
  test "gestpay_verified_by_visa should redirect to login" do
    post :gestpay_verified_by_visa
    assert_redirected_to new_account_session_path
  end
  
  test "captive_portal_api" do
    account = Account.last()
    
    CONFIG['automatic_captive_portal_login'] = true
    # if disabled 
    if CONFIG['automatic_captive_portal_login'] == false
      # method should simply return false
      assert !account.captive_portal_login!
    #else
    #  # method should not raise an exception otherwise it means there's a misconfiguration issue
    #  account.captive_portal_login!
    end
  end
  
  test "status is_expired false" do
    AccountSession.create(users(:one))
    get :status_json
    assert_response :success
    
    # convert response into hash
    data = JSON::parse(response.body)
    
    assert_equal false, data['is_expired']
    assert_equal true, data['is_verified']
  end
  
  test "status is_expired true" do
    get :status_json
    assert_response :success
    
    # convert response into hash
    data = JSON::parse(response.body)
    
    assert_equal true, data['is_expired']
    assert_equal false, data['is_verified']
  end
end
