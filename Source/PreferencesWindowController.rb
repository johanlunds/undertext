#
#  PreferencesWindowController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-04-17.
#  Copyright (c) 2009 Johan Lundström.
#

class PreferencesWindowController < NSWindowController

  SERVICE = "Undertext"

  def init
    super_init
    @keychain = EMKeychainProxy.sharedProxy.genericKeychainItemForService_withUsername(SERVICE, SERVICE) ||
      EMKeychainProxy.sharedProxy.addGenericKeychainItemForService_withUsername_password(SERVICE, SERVICE, '')
    self
  end
  
  def password
    @keychain.password
  end
  
  def password=(value)
    @keychain.setPassword(value)
  end
  
  # returns username, password as array
  def authentication
    defaults = NSUserDefaults.standardUserDefaults
    if defaults['authEnabled']
      [defaults['username'], password]
    else
      ['', '']
    end    
  end
end
