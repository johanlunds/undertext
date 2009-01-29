#
#  Client.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström. All rights reserved.
#

require 'xmlrpc/client'

class Client

  HOST = "http://www.opensubtitles.org/xml-rpc"
  
  def initialize
    @client = XMLRPC::Client.new2(HOST)
    @token = nil
  end
  
  def logIn
    result = @client.call('LogIn', '', '', '', self.class.userAgent)
    @token = result['token'].to_s
  end
  
  # TODO: better check
  def isLoggedIn
    !@token.nil?
  end
  
  def serverInfo
    @client.call('ServerInfo')
  end
  
  private
  
    def self.userAgent
      "Undertext v#{AppController.appVersion}"
    end
end
