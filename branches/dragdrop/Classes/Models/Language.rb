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
  
  def <=>(other_sub)
    name <=> other_sub.name
  end
  
  def eql?(other_sub)
    name == other_sub.name
  end
  
  # must also define hash if defining eql?
  def hash
    @name.to_ruby.hash # to_ruby because NSString#hash doesn't work as expected
  end
end
