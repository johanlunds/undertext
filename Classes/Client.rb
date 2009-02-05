#
#  Client.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

require 'xmlrpc/client'
require 'zlib'
require 'stringio'

# Documentation at http://trac.opensubtitles.org/projects/opensubtitles
class Client

  HOST = "http://www.opensubtitles.org/xml-rpc"
  
  def initialize
    @client = FakeClient.new2 # XMLRPC::Client.new2(HOST)
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
  
  # Adds subs to movie objects. Returns number of subs found
  def searchSubtitles(movies)
    args = movies.map do |movie|
      {
        'sublanguageid' => '', # searches all languages, TODO
        'moviehash'     => movie.osdb_hash,
        'moviebytesize' => File.size(movie.filename)
      }
    end
  
    result = call('SearchSubtitles', @token, args)
    if result['data'] # false if no results
      subs = result['data'].map { |subInfo| Subtitle.alloc.initWithInfo(subInfo) }
      # match subs with movies and then add
      movies.each do |movie|
        movie.subtitles = subs.find_all { |sub| sub.info["MovieHash"] == movie.osdb_hash }
      end
      
      result['data'].size
    else
      0
    end
  end
  
  # takes a block for doing whatever with downloaded data for each sub
  def downloadSubtitles(subs)
    subIds = subs.map { |sub| sub.info["IDSubtitleFile"] }
    result = call('DownloadSubtitles', @token, subIds)
    
    result['data'].each do |subInfo|
      # find existing sub object for download
      sub = subs.find { |sub| sub.info["IDSubtitleFile"] == subInfo["idsubtitlefile"] }
      subData = self.class.decode_and_unzip(subInfo["data"])
      yield sub, subData
    end
  end
  
  private
  
    def self.userAgent
      "Undertext v#{AppController.appVersion}"
    end
    
    def call(method, *args)
      # convert NSObjects to Ruby equivalents before XMLRPC converting
      args.map! { |arg| arg.is_a?(NSObject) ? arg.to_ruby : arg }      
      result = @client.call(method, *args)
      # NSLog("Client#call: #{method}, #{args.inspect}: #{result.inspect}")
      result
    end
    
    def self.decode_and_unzip(data)
      Zlib::GzipReader.new(StringIO.new(XMLRPC::Base64.decode(data))).read
    end
end

class FakeClient
  def self.new2(*args)
    new
  end
  
  def call(method, *args)
    case method
    when 'LogIn'
      { 'token' => 'abc' }
    when 'ServerInfo'
      { 'subs_subtitle_files' => '123' }
    when 'SearchSubtitles', 'DownloadSubtitles'
      { 'data' => false } # might not work
    else
      nil
    end
  end
end