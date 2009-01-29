#
#  AppController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström. All rights reserved.
#

class AppController < OSX::NSWindowController
  include OSX

  ib_outlets :outline, :status
  
  def self.appVersion
    NSBundle.mainBundle.infoDictionary["CFBundleVersion"]
  end
  
  # TODO:
  # can add clickable link
  # http://www.cocoadev.com/index.pl?InsertHyperlink
  # http://www.cocoadev.com/index.pl?ClickableUrlInTextView
  # http://www.cocoadev.com/index.pl?ParsingHtmlInTextView
  # @status.setAttributedStringValue(NSAttributedString.alloc.init)
  def awakeFromNib
    @client = Client.new
    @client.logIn
    
    if @client.isLoggedIn
      total = @client.serverInfo['subs_subtitle_files']      
      @status.setStringValue("Logged in to OpenSubtitles.org (#{total} subtitles).")
    end
  end
  
  def application_openFiles(sender, filenames)
    # add in outline
  end
  
  # Can choose directory and/or multiple files (movies)
  def open(sender)
    open = NSOpenPanel.openPanel
    open.setAllowsMultipleSelection(true)
    open.setCanChooseDirectories(true)
    open.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(
      nil,
      nil,
      ["public.movie"],
      self.window,
      self,
      'openPanelDidEnd:returnCode:contextInfo:',
      nil
    )
  end
  
  def openPanelDidEnd_returnCode_contextInfo(sender, result, context)
    application_openFiles(nil, sender.filenames) if result == NSOKButton
  end
  
  def downloadSelected(sender)
    # Todo
  end
  ib_action :downloadSelected
end
