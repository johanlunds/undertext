#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < NSObject

  attr_accessor :info
  attr_reader :filename, :filtered_subtitles

  def initWithPath_langFilter(filename, langFilter)
    init
    @filename = filename
    @hash = nil
    @info = {}
    # the sub-arrays are empty so we don't need to call #filter yet
    @langFilter = langFilter
    # These have to be NSArray, see "ResultsTableController#sortData"
    @filtered_subtitles = @all_subtitles = [].to_ns
    @unique_languages = 0
    self
  end
  
  # Should be nil to show all
  def languageFilter=(value)
    @langFilter = value
    filter
  end
  
  def all_subtitles=(subs)
    @all_subtitles = subs.to_ns # need to be NSArray, see "ResultsTableController#sortData"
    subs.each { |sub| sub.movie = self }
    @unique_languages = subs.map { |sub| sub.language }.uniq.size
    filter
  end
  
  def download=(value)
    @filtered_subtitles.each { |sub| sub.download = value }
  end
  
  # checks if some, all or none of movie's subs is going to be downloaded
  def downloadState
    download_count = @filtered_subtitles.inject(0) do |download_count, sub|
      sub.download ? download_count + 1 : download_count
    end
    
    if download_count == 0
      NSOffState
    elsif download_count == @filtered_subtitles.size
      NSOnState
    else
      NSMixedState
    end
  end
  
  def search_url
    "http://www.opensubtitles.org/search/moviebytesize-#{File.size(@filename)}/moviehash-#{osdb_hash}"
  end
  
  def url
    "http://www.imdb.com/title/tt#{@info["MovieImdbID"]}" if @info["MovieImdbID"]
  end
  
  def title
    File.basename(@filename)
  end
  
  def languageName
    case @unique_languages
    when 0
      "No languages"
    when 1
      "1 language"
    else
      "#{@unique_languages} languages"
    end
  end
  
  def downloadCount
    ""
  end
  
  def osdb_hash
    @hash ||= compute_hash
  end
  
  def childAtIndex(index)
    @filtered_subtitles[index]
  end
  
  def childrenCount
    @filtered_subtitles.size
  end
  
  def isExpandable
    true
  end
  
  def isEnabled
    childrenCount > 0
  end
  
  private
  
    # Needs to be called if @all_subtitles or @langFilter changes
    def filter
      if @langFilter
        @filtered_subtitles = @all_subtitles.select { |sub| sub.language == @langFilter }
      else
        @filtered_subtitles = @all_subtitles
      end
    end

    # String#unpack in Ruby 1.8 only unpacks little-endian long long ints as
    # opposed to Python's struct.unpack() that can do native, little and big.
    # To workaround this we check endianness and, if needed, reverse packed
    # data before calling #unpack. BIG_ENDIAN is true on PPC, false on Intel.
    BIG_ENDIAN = [1].pack("s") == [1].pack("n")
    
    CHUNK_SIZE = 64 * 1024 # 64 kbytes

    # Start with filesize as hash. Then for both beginning and end of file:
    # read 64 kbytes and divide into 64 bit pieces. Sum with hash.
    # Make sure the hash is kept to 64 bits during the whole process.
    def compute_hash
      filesize = File.size(@filename)
      File.open(@filename, 'rb') do |f|
        first = f.read(CHUNK_SIZE)
        f.seek([0, filesize - CHUNK_SIZE].max, IO::SEEK_SET)
        second = f.read(CHUNK_SIZE)
        hash = [first, second].inject(filesize) do |hash, part|
          part.reverse! if BIG_ENDIAN
          part.unpack("Q*").inject(hash) do |hash, n|
            hash + n & 0xffffffffffffffff
          end
        end
        
        "%016x" % hash
      end
    end
end
