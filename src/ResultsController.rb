#
#  ResultsController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsController < NSObject
  
  ALL_LANGUAGES = "Show all"
  
  ib_outlets :outline, :infoController, :selectedCount, :downloadSelected
  attr_reader :movies, :language
  
  def init
    super_init
    @movies = [].to_ns # need to be NSArray, see "outlineView_sortDescriptorsDidChange"
    @language = nil
    self
  end
  
  ib_action :languageSelected
  def languageSelected(sender)
    @language = if sender.selectedItem.title == ALL_LANGUAGES
      nil
    else
      sender.selectedItem.representedObject
    end
    reloadData
  end
  
  # subs to download
  def downloads
    @movies.inject([]) do |downloads, movie|
      downloads + movie.subtitles.select { |sub| sub.download? }
    end
  end
  
  def add_movies(movies)
    @movies += movies
    reloadData
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
    reloadData # because other items could have changed values
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
  
  def outlineView_sortDescriptorsDidChange(outline, oldDescriptors)
    reloadData
  end
  
  def reloadData
    sortData
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
    
    # arrays need to be NSArray (because they have method "sortUsingDescriptors")
    def sortData
      @movies.each { |movie| movie.all_subtitles.sortUsingDescriptors(@outline.sortDescriptors) }
      @movies.sortUsingDescriptors(@outline.sortDescriptors)
    end
end
