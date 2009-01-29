#
#  ResultsDataSource.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsDataSource < OSX::NSObject
  include OSX
  
  ib_outlet :outline
  attr_reader :movies
  
  def init
    super_init
    @movies = []
    self
  end
  
  def setFiles(files)
    @movies = files.map { |file| Movie.alloc.initWithFile(file) }
    @outline.reloadItem_reloadChildren(nil, true) # reload everything
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
