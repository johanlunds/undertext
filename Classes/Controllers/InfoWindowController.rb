#
#  InfoWindowController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-02-05.
#  Copyright (c) 2009 Johan Lundström.
#

class InfoWindowController < NSWindowController

  ib_outlets :table
  
  def init
    super_init
    @info = []
    @defaultInfo = []
    self
  end
  
  def item=(item)
    @info = item.nil? ? @defaultInfo : item.info.to_a.sort
    @table.reloadData
  end
  
  # will get shown when we have nothing else
  def defaultInfo=(default)
    @defaultInfo = @info = default.to_a.sort
    @table.reloadData
  end
  
  def numberOfRowsInTableView(table)
    @info.size
  end
  
  def tableView_objectValueForTableColumn_row(table, tableColumn, row)
    @info[row].send(tableColumn.identifier)
  end
end
