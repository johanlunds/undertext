#
#  ResultsController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsController < NSObject
  
  CHECK_TAG = 1
  
  ib_outlets :outline, :infoController, :selectedCount, :downloadSelected
  attr_reader :movies
  
  def init
    super_init
    @movies = [].to_ns # need to be NSArray, see "sortData"
    self
  end
  
  ib_action :languageSelected
  def languageSelected(sender)
    @movies.each { |movie| movie.languageFilter = sender.selectedItem.representedObject }
    reloadData
  end
  
  # both for check and uncheck
  ib_action :checkSelected
  def checkSelected(sender)
    value = (sender.tag == CHECK_TAG)
    @outline.selectedItems.each { |item| item.download = value }
    reloadData
  end
  
  ib_action :onlyCheckSelected
  def onlyCheckSelected(sender)
    @movies.each { |movie| movie.download = false }
    checkSelected(sender)
  end
  
  ib_action :openFile
  def openFile(sender)
    path = @outline.selectedItem.filename
    NSWorkspace.sharedWorkspace.openFile(path)
  end
  
  ib_action :revealFile
  def revealFile(sender)
    path = @outline.selectedItem.filename
    NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(path, nil)
  end
  
  ib_action :openURL
  def openURL(sender)
    url = @outline.selectedItem.url
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(url))
  end
  
  ib_action :openIMDB
  def openIMDB(sender)
    url = @outline.selectedItem.imdb_url
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(url))
  end
  
  def validateMenuItem(item)
    return false if @outline.numberOfSelectedRows <= 0
    
    case item.action
    when 'openFile:', 'revealFile:'
      File.exists?(@outline.selectedItem.filename)
    when 'openIMDB:'
      !@outline.selectedItem.imdb_url.nil?
    else
      true
    end
  end
  
  # subs to download
  def downloads
    @movies.inject([]) do |downloads, movie|
      downloads + movie.filtered_subtitles.select { |sub| sub.download }
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
    if tableColumn.identifier == "downloadState"
      cell.setTitle(item.title)
      cell.setEnabled(item.isEnabled)
    else
      cell.setTextColor(item.isEnabled ? NSColor.controlTextColor : NSColor.disabledControlTextColor)
    end
  end
  
  # setting checked state. movies does it for each of it's subtitles
  def outlineView_setObjectValue_forTableColumn_byItem(outline, value, tableColumn, item)
    item.download = (value != NSOffState)
    reloadData
  end
  
  # Update info window with selected item (or nil)
  def outlineViewSelectionDidChange(notification)
    @infoController.item = @outline.selectedItem
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
        sub_count + movie.filtered_subtitles.size
      end
      @downloadSelected.setEnabled(sel_count != 0)
      @selectedCount.setStringValue("#{sel_count}/#{sub_count} selected")
    end
    
    # arrays need to be NSArray (because they have method "sortUsingDescriptors")
    def sortData
      @movies.each { |movie| movie.filtered_subtitles.sortUsingDescriptors(@outline.sortDescriptors) }
      @movies.sortUsingDescriptors(@outline.sortDescriptors)
    end
end
