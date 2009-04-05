#
#  Subtitle.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Subtitle < NSObject

  attr_accessor :movie
  attr_reader :info, :download, :language
  
  def initWithInfo(info)
    init
    @info = info
    @download = NSOffState
    @movie = nil
    @language = Language.alloc.initWithInfo(info)
    self
  end
  
  # Calculate filename for sub using movie's filename
  def filename(add_language)
    path = @movie.filename.chomp(File.extname(@movie.filename))
    path += ".#{@language.iso6392}" if add_language
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
  
  def otherInfo
    @language.name
  end
  
  def downloadCount
    @info["SubDownloadsCnt"].to_i
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
