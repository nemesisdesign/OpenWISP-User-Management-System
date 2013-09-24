require 'test_helper'

class AccountsHelperTest < ActionView::TestCase
  
  test "user_selected_prefix" do
    prefixes = MobilePrefix.all
    assert_equal 44, user_selected_prefix(prefixes, 'en')
    assert_equal 44, user_selected_prefix(prefixes, 'gb')
    assert_equal 44, user_selected_prefix(prefixes, 'en-gb')
    assert_equal 1, user_selected_prefix(prefixes, 'en-us')
    assert_equal 1, user_selected_prefix(prefixes, 'en-ca')
    assert_equal 64, user_selected_prefix(prefixes, 'en-nz')
    assert_equal 39, user_selected_prefix(prefixes, 'it')
    assert_equal 39, user_selected_prefix(prefixes, 'it-it')
    assert_equal 34, user_selected_prefix(prefixes, 'es')
    assert_equal 34, user_selected_prefix(prefixes, 'ca')
    assert_equal 34, user_selected_prefix(prefixes, 'eu')
    assert_equal '', user_selected_prefix(prefixes, nil)
    assert_equal '', user_selected_prefix(prefixes, '')
  end
  
end
