#
#  Client.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

require 'xmlrpc/client'

class Client

  HOST = "http://www.opensubtitles.org/xml-rpc"
  
  def initialize
    @client = XMLRPC::Client.new2(HOST)
    @token = nil
  end
  
  # Log in anonymously
  def logIn
    result = call('LogIn', '', '', '', self.class.userAgent)
    @token = result['token']
  end
  
  # TODO: better check
  def isLoggedIn
    !@token.nil?
  end
  
  def serverInfo
    call('ServerInfo')
  end
  
  # TODO: return matched with movie objects, insert into outlineView and create sub objects
  def searchSubtitles(movies)
    args = movies.map do |movie|
      {
        'sublanguageid' => '', # searches all languages, TODO
        'moviehash'     => movie.osdb_hash,
        'moviebytesize' => File.size(movie.filename)
      }
    end
  
    result = call('SearchSubtitles', @token, args)
    result['data']
  end
  
  private
  
    def self.userAgent
      "Undertext v#{AppController.appVersion}"
    end
    
    def call(method, *args)
      @client.call(method, *args)
    end
end
