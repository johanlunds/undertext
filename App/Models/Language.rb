#
#  Language.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-03-10.
#  Copyright (c) 2009 Johan Lundström.
#

class Language < NSObject

  include Comparable
  
  NO_FLAG_IMAGE = "unknown.png"

  attr_reader :name, :iso6391, :iso6392

  def initWithInfo(info)
    init
    @name = info["LanguageName"]
    @iso6391 = info["ISO639"]
    @iso6392 = info["SubLanguageID"]
    self
  end
  
  def image
    NSImage.imageNamed(@iso6391 + ".png") || NSImage.imageNamed(NO_FLAG_IMAGE)
  end
  
  # Here are some compare methods for use with arrays (sort, uniq). Do sorts by
  # display name but do stricter checks when comparing equality (==, eql?, hash).
  # eql? and hash should always be defined together (see Object#hash doc).
  
  def <=>(other_sub)
    eql?(other_sub) ? 0 : name <=> other_sub.name
  end
  
  def eql?(other_sub)
    iso6392 == other_sub.iso6392
  end
  
  def hash
    @iso6392.hash
  end
end
