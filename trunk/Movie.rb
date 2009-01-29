#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström. All rights reserved.
#

class Movie

  attr_reader :filename

  def initialize(filename)
    @filename = filename
    @hash = nil
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
end
