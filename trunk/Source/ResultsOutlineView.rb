#
#  ResultsOutlineView.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-04-08.
#  Copyright (c) 2009 Johan Lundström.
#

class ResultsOutlineView < NSOutlineView

  ib_outlets :movieMenu
  
  # todo: fix selection
  def menuForEvent(event)
    item = itemAtRow(rowAtPoint(convertPoint_fromView(event.locationInWindow, nil)))
    if item.is_a? Movie
      @movieMenu
    else
      menu
    end
  end
end
