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
  attr_reader :movies, :language
  
  def init
    super_init
    @movies = [].to_ns # need to be NSArray, see "sortData"
    @language = nil
    self
  end
  
  ib_action :languageSelected
  def languageSelected(sender)
    @language = sender.selectedItem.representedObject
    reloadData
  end
  
  # both for check and uncheck
  ib_action :checkSelected
  def checkSelected(sender)
    value = (sender.tag == CHECK_TAG)
    @outline.selectedRowIndexes.to_a.each do |row|
      @outline.itemAtRow(row).download = value
    end
    reloadData
  end
  
  ib_action :onlyCheckSelected
  def onlyCheckSelected(sender)
    @movies.each { |movie| movie.download = false }
    checkSelected(sender)
  end
  
  ib_action :openFile
  def openFile(sender)
    path = @outline.itemAtRow(@outline.selectedRow).filename
    NSWorkspace.sharedWorkspace.openFile(path)
  end
  
  ib_action :revealFile
  def revealFile(sender)
    path = @outline.itemAtRow(@outline.selectedRow).filename
    NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(path, nil)
  end
  
  ib_action :openURL
  def openURL(sender)
    url = @outline.itemAtRow(@outline.selectedRow).url
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(url))
  end
  
  ib_action :openIMDB
  def openIMDB(sender)
    url = @outline.itemAtRow(@outline.selectedRow).imdb_url
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(url))
  end
  
  def validateMenuItem(item)
    return false if @outline.numberOfSelectedRows <= 0
    
    case item.action
    when 'openFile:', 'revealFile:'
      File.exists?(@outline.itemAtRow(@outline.selectedRow).filename)
    when 'openIMDB:'
      !@outline.itemAtRow(@outline.selectedRow).imdb_url.nil?
    else
      true
    end
  end
  
  # subs to download
  def downloads
    @movies.inject([]) do |downloads, movie|
      downloads + movie.subtitles.select { |sub| sub.download }
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
    cell.setTitle(item.title) if tableColumn.identifier == "downloadState"
  end
  
  # setting checked state. movies does it for each of it's subtitles
  def outlineView_setObjectValue_forTableColumn_byItem(outline, value, tableColumn, item)
    item.download = (value != NSOffState)
    reloadData
  end
  
  # Update info window with selected item (or nil)
  def outlineViewSelectionDidChange(notification)
    @infoController.item = @outline.itemAtRow(@outline.selectedRow)
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
