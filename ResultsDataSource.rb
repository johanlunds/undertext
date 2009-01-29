#
#  ResultsDataSource.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström. All rights reserved.
#

class ResultsDataSource < OSX::NSObject
  include OSX
  
  def setFiles(files)
    @movies = [] # removes existing ones. todo other cleanup...
  end
  
  def outlineView_child_ofItem(outline, index, item)
    nil
  end

  def outlineView_isItemExpandable(outline, item) 
    false
  end

  def outlineView_numberOfChildrenOfItem(outline, item)
    0
  end

  def outlineView_objectValueForTableColumn_byItem(outline, tableColumn, item)
    item.send(tableColumn.identifier)
  end
end
