#
#  Movie.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class Movie < NSObject

  attr_reader :filename, :subtitles

  def initWithFile(filename)
    init
    @filename = filename
    @hash = nil
    @subtitles = []
    self
  end
  
  # Notifying observers
  def subtitles=(subs)
    @subtitles = subs
    subs.each { |sub| sub.movie = self }
  end
  
  def download=(value)
    @subtitles.each { |sub| sub.download = value }
  end
  
  # checks if some, all or none of movie's subs is going to be downloaded
  # TODO: why has movies without subs a checked state?
  def download
    download_count = @subtitles.inject(0) do |download_count, sub|
      sub.download? ? download_count + 1 : download_count
    end
    
    if download_count == @subtitles.size
      NSOnState
    elsif download_count == 0
      NSOffState
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
  
  def osdb_hash
    @hash ||= MovieHasher.compute_hash(@filename)
  end
  
  def childAtIndex(index, language)
    filtered_subtitles(language)[index]
  end
  
  def childrenCount(language)
    filtered_subtitles(language).size
  end
  
  def isExpandable
    true
  end
  
  private
  
    def filtered_subtitles(language)
      if language.nil?
        @subtitles
      else
        @subtitles.find_all { |sub| sub.info["LanguageName"] == language }
      end
    end
end
