#
#  ResultsDataSource.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsDataSource < NSObject
  
  ib_outlet :outline
  attr_reader :movies
  
  def init
    super_init
    @movies = []
    # add notification for events fired in this class and Movie
    NSNotificationCenter.defaultCenter.addObserver_selector_name_object(self, 'reloadResults', 'NewItems', nil)
    self
  end
  
  # todo: is this correct?
  def dealloc
    NSNotificationCenter.defaultCenter.removeObserver(self)
    super_dealloc
  end
  
  def setFiles(files)
    @movies = files.map { |file| Movie.alloc.initWithFile(file) }
    NSNotificationCenter.defaultCenter.postNotificationName_object_('NewItems', nil)
  end
  
  def reloadResults(notification)
    sender = notification.object
    @outline.reloadItem_reloadChildren(sender, true) # reloads everything if item is nil
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
end
