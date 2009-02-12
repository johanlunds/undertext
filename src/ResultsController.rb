#
#  ResultsController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsController < NSObject
  
  ib_outlets :outline, :infoController
  attr_reader :movies
  
  def init
    super_init
    @movies = []
    self
  end
  
  def selectedCount
    downloads.size
  end
  
  def subtitleCount
    @movies.inject(0) do |sub_count, movie|
      sub_count + movie.subtitles.size
    end
  end
  
  # todo: nicer implementation
  def updateCounts
    willChangeValueForKey('subtitleCount') # need to call this before 'did' method
    didChangeValueForKey('subtitleCount')
    willChangeValueForKey('selectedCount') # need to call this before 'did' method
    didChangeValueForKey('selectedCount')
  end
  
  # subs to download
  def downloads
    @movies.inject([]) do |downloads, movie|
      downloads + movie.subtitles.select { |sub| sub.download? }
    end
  end
  
  # set language and reload outline only showing subs in this language
  def language=(lang)
    @movies.each { |movie| movie.sub_language = lang }
    updateCounts
    @outline.reloadData
  end
  
  def files=(files)
    @movies = files.map { |file| Movie.alloc.initWithFile(file) }
    @outline.reloadData
  end
  
  def outlineView_child_ofItem(outline, index, item)
    item.nil? ? @movies[index] : item.childAtIndex(index)
  end

  def outlineView_isItemExpandable(outline, item) 
    item.isExpandable
  end

  def outlineView_numberOfChildrenOfItem(outline, item)
    item.nil? ? @movies.size : item.childrenCount
  end

  def outlineView_objectValueForTableColumn_byItem(outline, tableColumn, item)
    item.send(tableColumn.identifier)
  end
  
  def outlineView_willDisplayCell_forTableColumn_item(outline, cell, tableColumn, item)
    cell.setTitle(item.title) if tableColumn.identifier == "download"
  end
  
  # setting checked state
  def outlineView_setObjectValue_forTableColumn_byItem(outline, value, tableColumn, item)
    item.download = value
    updateCounts
    @outline.reloadData # because other items could have changed values
  end
  
  # Update info window with selected sub (or nil)
  def outlineViewSelectionDidChange(notification)
    sub = nil
    if @outline.selectedRow != -1
      item = @outline.itemAtRow(@outline.selectedRow)
      sub = item if item.is_a? Subtitle
    end
    @infoController.subtitle = sub
  end
end
