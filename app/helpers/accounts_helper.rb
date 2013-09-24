# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

module AccountsHelper
  def link_to_paypal(link, args)
    account = args[:bill_to]
    args.delete :bill_to

    link_to(link, account.verify_with_paypal(account_url, verify_paypal_url), args) if account
  end

  def encrypted_submit_to_paypal(submit, args)
    account = args[:bill_to]
    args.delete :bill_to
    paypal_form = ""

    if account
      paypal_url, enc_data = account.encrypted_verify_with_paypal(account_url, secure_verify_paypal_url)

      paypal_form = form_tag paypal_url, args
      paypal_form += hidden_field_tag :cmd, "_s-xclick"
      paypal_form += hidden_field_tag :encrypted, enc_data
      paypal_form += submit
      paypal_form += "</form>"
    end

    paypal_form
  end

  def account_verification_methods
    User.self_verification_methods
  end

  def account_verification_select
    options = ["select_verification_method"] + account_verification_methods
    options.map{ |method| [ t(method.to_sym), method ] }
  end
  
  def mobile_prefixes_select(prefixes)
    # return a collection of prefixes for an HTML select
    # Example:
    # value: 39  label: Italy (+39)
    prefixes.map{ |prefix| ["#{prefix.name} (+#{prefix.prefix})", prefix.prefix]}
  end
  
  def user_selected_prefix(prefixes, lang=nil)
    lang = lang.nil? ? user_language.downcase : lang
    
    # if nothing check if it's simply "en" and return gb
    if lang == 'en'
      return 44
    elsif lang == 'ca'  # catalunya has spanish prefix
      # wont process 'en-ca' which is canadian english
      return 34
    elsif lang == 'eu'  # baseque has spanish prefix
      return 34
    end
    
    # determine user prefix based on his preferred language
    # try first to intercept last two letters
    # (because in the case of en-us we want to select "us")
    begin
      lang_suffix = lang[-2,2]
    rescue NoMethodError
      # no preferred language set, return empty string
      # user will have to manually select prefix
      return ''
    end
    
    prefixes.each do |prefix|
      if prefix.code == lang_suffix
        return prefix.prefix
      end
    end
    
    # and if nothing is found try the first two letters instead
    lang_prefix = lang[0,2]
    
    prefixes.each do |prefix|
      if prefix.code == lang_prefix
        return prefix.prefix
      end
    end
    
    return ''
  end
  
  def user_language
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first rescue ''
  end
end
