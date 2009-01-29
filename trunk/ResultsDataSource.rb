#
#  ResultsDataSource.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-29.
#  Copyright (c) 2009 Johan Lundström. All rights reserved.
#

class ResultsDataSource < OSX::NSObject
  include OSX
  
  ib_outlet :outline
  
  def init
    super_init
    @movies = []
    self
  end
  
  def setFiles(files)
    @movies = files.map { |file| Movie.new(file) } 
    @outline.reloadItem_reloadChildren(nil, true) # reload everything
  end
  
  def outlineView_child_ofItem(outline, index, item)
    if item.nil?
      @movies[index]
    else
      nil
    end
  end

  def outlineView_isItemExpandable(outline, item) 
    false
  end

  def outlineView_numberOfChildrenOfItem(outline, item)
    if item.nil?
      @movies.size
    else
      0
    end
  end

  def outlineView_objectValueForTableColumn_byItem(outline, tableColumn, item)
    item.send(tableColumn.identifier)
  end
end
