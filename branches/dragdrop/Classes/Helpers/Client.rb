#
#  Client.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

require 'zlib'
require 'stringio'

# Documentation at http://trac.opensubtitles.org/projects/opensubtitles
class Client

  # For any connectivity problems concerning XMLRPC.
  class ConnectionError < StandardError
  end

  HOST = "http://api.opensubtitles.org/xml-rpc"
  
  # empty username and password becomes anonymous login
  def initialize(username, password)
    @username = username
    @password = password
    @token = nil
  end
  
  def user
    @username.empty? ? "anonymous" : @username
  end
  
  def logIn
    result = call('LogIn', @username, @password, '', self.class.userAgent)
    @token = result['token']
  end
  
  def serverInfo
    info = call('ServerInfo')
    info.delete("last_update_strings") # last_update_strings is unsuitable to show because it's a hash
    info.delete("application") # application is confusing because of the key-name
    info
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
      subData = self.class.decode_base64_and_unzip(subInfo["data"])
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
      request = XMLRPCRequest.alloc.initWithURL(NSURL.URLWithString(HOST))
      request.setMethod_withParameters(method, args)
      response = XMLRPCConnection.sendSynchronousXMLRPCRequest(request)
      
      unless self.class.response_ok?(response)
        @token = nil
        raise ConnectionError, "Unknown error"
      end
      
      response.object
    end
    
    # Does a result exist and if so is there a status we should check?
    def self.response_ok?(response)
      response && response.object && (!response.object['status'] || (200..299) === response.object['status'].to_i)
    end
    
    def self.decode_base64_and_unzip(data)
      Zlib::GzipReader.new(StringIO.new(data.unpack("m")[0])).read
    end
end