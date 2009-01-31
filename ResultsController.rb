#
#  ResultsController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsController < NSObject
  
  ib_outlet :outline
  attr_reader :movies
  
  def init
    super_init
    @movies = []
    # add notification for events fired in this class and Movie
    NSNotificationCenter.defaultCenter.addObserver_selector_name_object(self, 'newSubtitles', 'NewSubtitles', nil)
    self
  end
  
  # todo: is this correct?
  def dealloc
    NSNotificationCenter.defaultCenter.removeObserver(self)
    super_dealloc
  end
  
  def setFiles(files)
    @movies = files.map { |file| Movie.alloc.initWithFile(file) }
    @outline.reloadData
  end
  
  def newSubtitles(notification)
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
    @outline.reloadData # because other items could have changed values
  end
end
