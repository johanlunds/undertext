#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < OSX::NSObject
  include OSX

  attr_reader :filename
  attr_accessor :subtitles

  def initWithFile(filename)
    init
    @filename = filename
    @hash = nil
    @subtitles = []
    self
  end
  
  def title
    File.basename(@filename)
  end
  
  def otherInfo
    osdb_hash
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
end
