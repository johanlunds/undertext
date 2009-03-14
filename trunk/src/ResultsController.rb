#
#  ResultsController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsController < NSObject
  
  ib_outlets :outline, :infoController, :selectedCount, :downloadSelected
  attr_reader :movies, :language
  
  def init
    super_init
    @movies = []
    @language = nil
    self
  end
  
  # subs to download
  def downloads
    @movies.inject([]) do |downloads, movie|
      downloads + movie.subtitles.select { |sub| sub.download? }
    end
  end
  
  # nil if show all subs
  def language=(value)
    @language = value
    reload
  end
  
  def files=(files)
    @movies = files.map { |file| Movie.alloc.initWithFile(file, self) }
    reload
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
    reload # because other items could have changed values
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
  
  def reload
    @outline.reloadData
    updateCounts
  end
  
  private
  
    def updateCounts
      sel_count = downloads.size
      sub_count = @movies.inject(0) do |sub_count, movie|
        sub_count + movie.subtitles.size
      end
      @downloadSelected.setEnabled(sel_count != 0)
      @selectedCount.setStringValue("#{sel_count}/#{sub_count} selected")
    end
end
