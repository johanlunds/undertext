#
#  AppController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

class AppController < OSX::NSObject
  ib_outlet :table
  
  def awakeFromNib
    # @client = Client.new
  end
  
  def application_openFiles_(sender, filenames)
    # fill table
  end
end
