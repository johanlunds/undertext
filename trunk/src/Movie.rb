#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < NSObject

  attr_reader :filename, :all_subtitles

  def initWithFile(filename, resController)
    init
    @filename = filename
    @hash = nil
    # need to be NSArray, see "ResultsController#sortData"
    @all_subtitles = [].to_ns
    @resController = resController
    self
  end
  
  # filtered by language
  def subtitles
    if @resController.language.nil?
      @all_subtitles
    else
      @all_subtitles.select { |sub| sub.language == @resController.language }
    end
  end
  
  def subtitles=(subs)
    @all_subtitles = subs.to_ns
    subs.each { |sub| sub.movie = self }
  end
  
  def download=(value)
    subtitles.each { |sub| sub.download = value }
  end
  
  # checks if some, all or none of movie's subs is going to be downloaded
  def downloadState
    download_count = subtitles.inject(0) do |download_count, sub|
      sub.download ? download_count + 1 : download_count
    end
    
    if download_count == 0
      NSOffState
    elsif download_count == subtitles.size
      NSOnState
    else
      NSMixedState
    end
  end
  
  def title
    File.basename(@filename)
  end
  
  def otherInfo
    ""
  end
  
  def downloadCount
    ""
  end
  
  def osdb_hash
    @hash ||= MovieHasher.compute_hash(@filename)
  end
  
  def childAtIndex(index)
    subtitles[index]
  end
  
  def childrenCount
    subtitles.size
  end
  
  def isExpandable
    true
  end
end
