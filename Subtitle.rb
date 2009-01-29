#
#  Subtitle.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Subtitle < NSObject
  
  attr_reader :info
  
  # todo: remove movie info (keys starting with "Movie")
  # todo: when need to filter etc by language, create language class
  def initWithInfo(info)
    init
    @info = info
    self
  end
  
  def title
    @info["SubFileName"]
  end
  
  # todo: show other useful info
  def otherInfo
    @info["LanguageName"]
  end
  
  def childAtIndex(index)
    nil
  end
  
  def childrenCount
    0
  end
  
  def isExpandable
    false
  end
end
