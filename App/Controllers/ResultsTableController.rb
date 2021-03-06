#
#  ResultsTableController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsTableController < NSObject
  
  CHECK_TAG = 1
  
  ib_outlets :appController, :detailsController
  ib_outlets :outline, :tableCounts, :downloadButton
  attr_reader :movies
  
  def init
    super_init
    @movies = [].to_ns # need to be NSArray, see "sortData"
    self
  end
  
  def awakeFromNib
    @outline.registerForDraggedTypes([NSFilenamesPboardType])
  end
  
  # accept drops of movie files and folders ONLY
  def outlineView_validateDrop_proposedItem_proposedChildIndex(outline, info, item, index)
    files = info.draggingPasteboard.propertyListForType(NSFilenamesPboardType)
    if self.class.contains_non_movie_files? files
      NSDragOperationNone
    else
      @outline.setDropItem_dropChildIndex(nil, NSOutlineViewDropOnItemIndex) # retarget to root node
      NSDragOperationGeneric
    end
  end
  
  def outlineView_acceptDrop_item_childIndex(outline, info, item, index)
    files = info.draggingPasteboard.propertyListForType(NSFilenamesPboardType)
    @appController.application_openFiles(nil, files)
    true # drop operation was successful
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
    @outline.selectedItems.each do |item|
      if File.exists?(item.filename)
        NSWorkspace.sharedWorkspace.openFile(item.filename)
      end
    end
  end
  
  ib_action :revealFile
  def revealFile(sender)
    @outline.selectedItems.each do |item|
      if File.exists?(item.filename)
        NSWorkspace.sharedWorkspace.selectFile_inFileViewerRootedAtPath(item.filename, nil)
      end
    end
  end
  
  ib_action :openDetailsURL
  def openDetailsURL(sender)
    @outline.selectedItems.each do |item|
      if item.url
        NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(item.url))
      end
    end
  end
  
  ib_action :openSearchURL
  def openSearchURL(sender)
    @outline.selectedItems.each do |item|
      if item.is_a?(Movie)
        NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(item.search_url))
      end
    end
  end
  
  def validateMenuItem(item)
    return false if @outline.numberOfSelectedRows <= 0
    
    case item.action
    when 'openFile:', 'revealFile:'
      @outline.selectedItems.any? { |item| File.exists?(item.filename) }
    when 'openDetailsURL:'
      @outline.selectedItems.any? { |item| item.url }
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
    @movies.concat(movies)
    reloadData
    movies.each { |movie| @outline.expandItem(movie) } # expand new items by default
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
    case tableColumn.identifier
    when "downloadState"
      cell.setTitle(item.title)
    when "languageName"
      cell.setImage(item.is_a?(Subtitle) ? item.language.image : nil)
    end
    
    if tableColumn.identifier == "downloadState"
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
  
  # Update details window with selected item (or nil)
  def outlineViewSelectionDidChange(notification)
    @detailsController.item = @outline.selectedItem
  end
  
  # keeps the currently selected items by selecting them at the new row indexes
  def outlineView_sortDescriptorsDidChange(outline, oldDescriptors)
    selected = @outline.selectedItems
    reloadData
    @outline.selectItems(selected)
  end
  
  def reloadData
    sortData
    @outline.reloadData
    updateCounts
  end
  
  private
  
    def updateCounts
      checked = downloads.size
      filtered = @movies.inject(0) do |filtered, movie|
        filtered + movie.filtered_subtitles.size
      end
      @downloadButton.setEnabled(checked != 0)
      @tableCounts.setStringValue("#{checked} checked of #{filtered} total")
    end
    
    # arrays need to be NSArray (because they have method "sortUsingDescriptors")
    def sortData
      @movies.each { |movie| movie.filtered_subtitles.sortUsingDescriptors(@outline.sortDescriptors) }
      @movies.sortUsingDescriptors(@outline.sortDescriptors)
    end
    
    def self.contains_non_movie_files?(files)
      files.any? do |file|
        File.file?(file) && !AppController::MOVIE_EXTS.include?(File.extname(file).sub(".", ""))
      end
    end
end
