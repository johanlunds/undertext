#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < NSObject

  CHUNK_SIZE = 64 * 1024 # 64 kbytes, used in compute_hash

  attr_accessor :info
  attr_reader :filename, :all_subtitles

  def initWithFile(filename, resController)
    init
    @filename = filename
    @hash = nil
    @info = {}
    # need to be NSArray, see "ResultsController#sortData"
    @all_subtitles = [].to_ns
    @unique_languages = 0
    @resController = resController
    self
  end
  
  # filtered by language
  def subtitles
    if @resController.language.nil?
      @all_subtitles
    else
      @all_subtitles.select { |sub| sub.language == @resController.language }
    end
  end
  
  # Argument must be NSArray, which it always is because method is called with result from XMLRPC.framework
  def subtitles=(subs)
    @all_subtitles = subs
    subs.each { |sub| sub.movie = self }
    @unique_languages = subs.to_ruby.map { |sub| sub.language }.uniq.size # to_ruby because of RubyCocoa bug
  end
  
  def download=(value)
    subtitles.each { |sub| sub.download = value }
  end
  
  # checks if some, all or none of movie's subs is going to be downloaded
  def downloadState
    download_count = subtitles.inject(0) do |download_count, sub|
      sub.download ? download_count + 1 : download_count
    end
    
    if download_count == 0
      NSOffState
    elsif download_count == subtitles.size
      NSOnState
    else
      NSMixedState
    end
  end
  
  def url
    "http://www.opensubtitles.org/search/moviebytesize-#{File.size(@filename)}/moviehash-#{osdb_hash}"
  end
  
  def imdb_url
    "http://www.imdb.com/title/tt#{@info["MovieImdbID"]}" if @info["MovieImdbID"]
  end
  
  def title
    File.basename(@filename)
  end
  
  def otherInfo
    "#{@unique_languages} languages"
  end
  
  def downloadCount
    ""
  end
  
  def osdb_hash
    @hash ||= compute_hash
  end
  
  def childAtIndex(index)
    subtitles[index]
  end
  
  def childrenCount
    subtitles.size
  end
  
  def isExpandable
    true
  end
  
  private

    def compute_hash
      filesize = File.size(@filename)
      hash = filesize

      # Read 64 kbytes, divide up into 64 bits and add each
      # to hash. Do for beginning and end of file.
      File.open(@filename, 'rb') do |f|    
        # Q = unsigned long long = 64 bit
        f.read(CHUNK_SIZE).unpack("Q*").each do |n|
          hash = hash + n & 0xffffffffffffffff # to remain as 64 bit number
        end

        f.seek([0, filesize - CHUNK_SIZE].max, IO::SEEK_SET)

        # And again for the end of the file
        f.read(CHUNK_SIZE).unpack("Q*").each do |n|
          hash = hash + n & 0xffffffffffffffff
        end
      end
      
      "%016x" % hash
    end
end
