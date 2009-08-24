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
  
  # empty username and password becomes anonymous login
  def initialize(username, password)
    @client = XMLRPC::Client.new_from_uri(HOST)
    @token = nil
    @username = username
    @password = password
  end
  
  def logIn
    result = call('LogIn', @username, @password, '', self.class.userAgent)
    @token = result['token']
  end
  
  def serverInfo
    call('ServerInfo')
  end
  
  # Adds subs to movie objects.
  def searchSubtitles(movies)
    loginNeeded!
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
  # if "subs" is empty the XMLRPC result will have status = 408
  def downloadSubtitles(subs)
    loginNeeded!
    subIds = subs.map { |sub| sub.info["IDSubtitleFile"] }
    result = call('DownloadSubtitles', @token, subIds)
    
    result['data'].each do |subInfo|
      # find existing sub object for download
      sub = subs.find { |sub| sub.info["IDSubtitleFile"] == subInfo["idsubtitlefile"] }
      subData = self.class.decode_and_unzip(subInfo["data"])
      yield sub, subData
    end
  end
  
  def movieDetails(movies)
    loginNeeded!
    movieHashes = movies.map { |movie| movie.osdb_hash }
    result = call('CheckMovieHash', @token, movieHashes)
    
    movies.each do |movie|
      movie.info = result['data'][movie.osdb_hash] unless result['data'][movie.osdb_hash].empty?
    end
  end
  
  def languages
    result = call('GetSubLanguages')
    result['data'].map { |langInfo| Language.alloc.initWithInfo(langInfo) }
  end
  
  private
  
    def loginNeeded!
      logIn if @token.nil?
    end
  
    def self.userAgent
      "Undertext v#{NSBundle.mainBundle.infoDictionary["CFBundleVersion"]}"
    end
    
    # Calls method and raises if errors. Sets state to logged out if any errors.
    def call(method, *args)
      # convert NSObjects to Ruby equivalents before XMLRPC converting
      args.map! { |arg| arg.is_a?(NSObject) ? arg.to_ruby : arg }
      
      begin
        result = @client.call(method, *args)
      rescue SocketError, IOError, RuntimeError, SystemCallError, XMLRPC::FaultException, Timeout::Error => e
        # xmlrpc lib sometimes raises RuntimeError (HTTP 500 errors for example)
        # and SystemCallError = Errno::*
        @token = nil
        raise ConnectionError, "#{e.message} (#{e.class})"
      end
      
      if self.class.result_error?(result)
        @token = nil
        raise ConnectionError, "Result status was '#{result['status']}'"
      end
      
      result
    end
    
    def self.result_error?(result)
      result['status'] && !(200..299).include?(result['status'].to_i)
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
    when 'SearchSubtitles' # might stop working
      { 'data' => [{'LanguageName' => 'English', 'ISO639' => 'en', 'SubLanguageID' => 'eng', 'MovieHash' => args[1][0]['moviehash'], 'SubFormat' => 'srt', 'SubFileName' => 'hej.srt', 'SubDownloadsCnt' => '100', 'IDSubtitleFile' => '1'}] }
    when 'DownloadSubtitles'
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