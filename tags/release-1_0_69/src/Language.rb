#
#  Language.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-03-10.
#  Copyright (c) 2009 Johan Lundström.
#

class Language

  include Comparable

  attr_reader :name, :iso6391, :iso6392

  def initialize(info)
    @name = info["LanguageName"]
    @iso6391 = info["ISO639"]
    @iso6392 = info["SubLanguageID"]
  end
  
  def <=>(other_sub)
    name <=> other_sub.name
  end
end
