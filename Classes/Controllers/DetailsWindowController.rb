#
#  DetailsWindowController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-02-05.
#  Copyright (c) 2009 Johan Lundström.
#

class DetailsWindowController < NSWindowController

  ib_outlets :table
  
  def init
    super_init
    @info = []
    @defaultInfo = []
    self
  end
  
  def item=(item)
    @info = item.nil? ? @defaultInfo : self.class.convertAndPrettify(item.info)
    @table.reloadData
  end
  
  # will get shown when we have nothing else
  def defaultInfo=(default)
    @defaultInfo = @info = self.class.convertAndPrettify(default)
    @table.reloadData
  end
  
  def numberOfRowsInTableView(table)
    @info.size
  end
  
  def tableView_objectValueForTableColumn_row(table, tableColumn, row)
    @info[row].send(tableColumn.identifier)
  end
  
  private
  
    # normalize camelcase, remove underscores, then titleize.
    # code partly taken from ActiveSupport::Inflector
    def self.convertAndPrettify(hash)
      hash.to_a.sort.map do |key, value|
        prettyKey = key.gsub(/([A-Z]+)([A-Z][a-z])/, '\1 \2').
          gsub(/([a-z\d])([A-Z])/, '\1 \2').
          gsub('_', ' ').
          gsub(/\b([a-z])/) { $1.capitalize }
          
        [prettyKey, value]
      end
    end
end
