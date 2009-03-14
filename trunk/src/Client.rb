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

  # For any connectivity problems concerning XMLRPC.
  class ConnectionError < StandardError
  end

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
  
  # Adds subs to movie objects.
  def searchSubtitles(movies)
    args = movies.map do |movie|
      {
        'sublanguageid' => '', # searches all languages
        'moviehash'     => movie.osdb_hash,
        'moviebytesize' => File.size(movie.filename)
      }
    end
  
    result = call('SearchSubtitles', @token, args)
    if result['data'] # false if no results
      subs = result['data'].map { |subInfo| Subtitle.alloc.initWithInfo(subInfo) }
      # match subs with movies and then add
      movies.each do |movie|
        movie.subtitles = subs.select { |sub| sub.info["MovieHash"] == movie.osdb_hash }
      end
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
  
  # todo: cache or something
  def languages
    result = call('GetSubLanguages')
    result['data'].map { |langInfo| Language.new(langInfo) }
  end  
  
  private
  
    def self.userAgent
      "Undertext v#{AppController.appVersion}"
    end
    
    # TODO: consider adding SystemCallError/Errno to list of exceptions
    def call(method, *args)
      # convert NSObjects to Ruby equivalents before XMLRPC converting
      args.map! { |arg| arg.is_a?(NSObject) ? arg.to_ruby : arg }      
      result = @client.call(method, *args)
      # NSLog("Client#call: #{method}, #{args.inspect}: #{result.inspect}")
      self.class.check_result_status!(result)
      result
    rescue SocketError, IOError, RuntimeError, XMLRPC::FaultException => e
      # xmlrpc lib sometimes raises RuntimeError (HTTP 500 errors for example)
      raise ConnectionError, e.message
    end
    
    # raises if status is in result and not in range 200-299
    def self.check_result_status!(result)
      if result['status'] && !(200..299).include?(result['status'].to_i)
        raise ConnectionError, "OSDB result status: #{result['status']}"
      end
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
    when 'GetSubLanguages'
      { 'data' => [{ 'LanguageName' => 'English', 'ISO639' => 'en', 'SubLanguageID' => 'eng' }, { 'LanguageName' => 'Swedish', 'ISO639' => 'sv', 'SubLanguageID' => 'swe' }] }
    else
      nil
    end
  end
end

# Uncomment when no internet connection etc
# XMLRPC::Client = FakeClient