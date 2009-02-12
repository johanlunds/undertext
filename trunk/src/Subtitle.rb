#
#  Subtitle.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Subtitle < NSObject

  attr_accessor :movie
  attr_reader :info, :download
  
  # todo: remove movie info (keys starting with "Movie")
  # todo: when need to filter etc by language, create language class
  def initWithInfo(info)
    init
    @info = info
    @download = NSOffState
    @movie = nil
    self
  end
  
  # Calculate filename for sub using movie's filename
  def filename(add_language)
    path = @movie.filename.chomp(File.extname(@movie.filename))
    path += ".#{@info["SubLanguageID"]}" if add_language
    path += ".#{@info["SubFormat"]}"
    path
  end
  
  def download=(value)
    @download = (value != NSOffState) ? NSOnState : NSOffState
  end
  
  # boolean value instead of internal NSOnState/NSOffState
  def download?
    @download == NSOnState
  end
  
  def title
    @info["SubFileName"]
  end
  
  # todo: show other useful info
  def otherInfo
    @info["LanguageName"]
  end
  
  def childAtIndex(index, language)
    nil
  end
  
  def childrenCount(language)
    0
  end
  
  def isExpandable
    false
  end
end
