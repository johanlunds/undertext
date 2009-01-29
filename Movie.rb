#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < NSObject

  attr_reader :filename, :subtitles

  def initWithFile(filename)
    init
    @filename = filename
    @hash = nil
    @subtitles = []
    self
  end
  
  # Notifying observers
  def setSubtitles(subs)
    @subtitles = subs
    NSNotificationCenter.defaultCenter.postNotificationName_object_('NewItems', self)
  end
  
  def title
    File.basename(@filename)
  end
  
  def otherInfo
    ""
  end
  
  def osdb_hash
    @hash ||= MovieHasher.compute_hash(@filename)
  end
  
  def childAtIndex(index)
    @subtitles[index]
  end
  
  def childrenCount
    @subtitles.size
  end
  
  def isExpandable
    true
  end
  
  # match subs with movies and then add
  def self.addSubtitlesToMovies(movies, subs)
    movies.each do |movie|
      movie.setSubtitles(subs.find_all { |sub| sub.info["MovieHash"] == movie.osdb_hash })
    end
  end
end
