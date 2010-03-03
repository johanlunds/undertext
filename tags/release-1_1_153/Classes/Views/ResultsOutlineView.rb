#
#  ResultsOutlineView.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-04-08.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsOutlineView < NSOutlineView

  ib_outlets :movieMenu
  
  # outline has separate menus for movies and subtitles.
  # provides more natural selection behaviour: selects row under mouse pointer
  # because the menu shown will be for that kind of item.
  def menuForEvent(event)
    row = rowAtPoint(convertPoint_fromView(event.locationInWindow, nil))
    selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(row), isRowSelected(row)) if row >= 0
    
    if itemAtRow(row).is_a? Movie
      @movieMenu
    else
      menu
    end
  end
  
  def selectedItem
    itemAtRow(selectedRow)
  end
  
  def selectedItems
    selectedRowIndexes.to_a.map { |row| itemAtRow(row) }
  end
end
