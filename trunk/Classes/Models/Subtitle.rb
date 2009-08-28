#
#  Subtitle.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Subtitle < NSObject

  attr_accessor :movie, :download
  attr_reader :info, :language
  
  def initWithInfo(info)
    init
    @info = info
    @download = false
    @movie = nil
    @language = Language.alloc.initWithInfo(info)
    self
  end
  
  # todo: if already downloaded remember filename and return it
  # Calculate filename for sub using movie's filename
  def filename(add_language = false)
    path = @movie.filename.chomp(File.extname(@movie.filename))
    path += ".#{@language.iso6392}" if add_language
    path += ".#{@info["SubFormat"]}"
    path
  end
  
  def downloadState
    @download ? NSOnState : NSOffState
  end
  
  def url
    "http://www.opensubtitles.org/subtitles/#{@info["IDSubtitle"]}"
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
