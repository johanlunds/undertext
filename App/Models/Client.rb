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
    result = call('ServerInfo')
    result.delete("last_update_strings") # last_update_strings is unsuitable to show because it's a hash
    result.delete("application") # application is confusing because of the key-name
    result
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
        movie.all_subtitles = subs.select { |sub| sub.info["MovieHash"] == movie.osdb_hash }
      end
    end
  end
  
  # Downloaded data can be accessed by calling Subtitle#contents
  # if subs-argument is empty the XMLRPC result will have status = 408
  def downloadSubtitles(subs)
    loginNeeded!
    subIds = subs.map { |sub| sub.info["IDSubtitleFile"] }
    result = call('DownloadSubtitles', @token, subIds)
    
    result['data'].each do |subInfo|
      # find existing sub object for download
      sub = subs.find { |sub| sub.info["IDSubtitleFile"] == subInfo["idsubtitlefile"] }
      sub.contents = self.class.decode_base64_and_unzip(subInfo["data"])
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
      
      if self.class.xmlrpc_error?(response)
        @token = nil
        raise ConnectionError,
          "There was no, or a malformed, response from the server. " +
          "This usually occurs when there's no internet connection or the server is busy.\n\n" +
          "You can try opening http://www.opensubtitles.org in a browser to check if it's available."
      elsif self.class.error_status?(response)
        @token = nil
        raise ConnectionError,
          "The returned response from the server had the error status \"#{response.object['status']}\". " + 
          "This could be because of faulty input (for example wrong password) or perhaps a bug in Undertext.\n\n" + 
          "Please report any suspected bugs on Undertext's website."
      end
      
      # If not calling to_ruby it gets a bit tricky figuring out where in the
      # code there's NSObjects and regular Ruby objects.
      response.object.to_ruby
    end
    
    def self.xmlrpc_error?(response)
      !response || !response.object
    end
    
    # No status is an OK status
    def self.error_status?(response)
      response.object['status'] && !(200..299).include?(response.object['status'].to_i)
    end
    
    def self.decode_base64_and_unzip(data)
      Zlib::GzipReader.new(StringIO.new(data.unpack("m")[0])).read
    end
    
    # Encoding and zipping data for uploading:
    # [Zlib::Deflate.deflate(data)].pack("m")
end