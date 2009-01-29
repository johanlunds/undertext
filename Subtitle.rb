#
#  Subtitle.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Subtitle < OSX::NSObject
  include OSX
  
  def title
    "Subtitle"
  end
  
  def otherInfo
    ""
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
