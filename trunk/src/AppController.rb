#
#  AppController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

class AppController < NSObject
  
  # Used if looking by UTI is too cumbersome
  EXTS = %w(avi mpg mpeg wmv asf divx mov m2p moov omf qt rm dv 3ivx mkv ogm mp4 m4v)
  
  URLS = [
    'http://www.opensubtitles.org',
    'http://www.opensubtitles.org/upload',
    'http://code.google.com/p/undertext'
  ]
  
  NO_FLAG_IMAGE = "unknown.png"

  attr_accessor :addLanguageToFile
  ib_outlets :window, :resController, :connStatus, :workingStatus, :languages
  
  def init
    super_init
    @client = Client.new
    self
  end
  
  def awakeFromNib
    @workingStatus.setUsesThreadedAnimation(true) # todo: remove if changing to threaded api-calls
    connect_to_server!
  end
  
  def self.appVersion
    NSBundle.mainBundle.infoDictionary["CFBundleVersion"]
  end
  
  # for folders it searches recursively for movie files
  def application_openFiles(sender, paths)
    files, folders = paths.partition { |path| File.file? path }
    folders.each do |folder|
      files += Dir.glob(folder + "/**/*.{#{EXTS.join(',')}}")
    end
    @resController.files = files # todo: keep already existing results in outline
    search # populate outline with search results
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
      @window,
      self,
      'openPanelDidEnd:returnCode:contextInfo:',
      nil
    )
  end
  
  def openPanelDidEnd_returnCode_contextInfo(sender, result, context)
    application_openFiles(nil, sender.filenames) if result == NSOKButton
  end

  # todo: handle if file already exists (suffix with number or ask)
  # todo: only call client if any subs selected (otherwise RPC call will be false)
  ib_action :downloadSelected  
  def downloadSelected(sender)
    do_work do
      @client.downloadSubtitles(@resController.downloads) do |sub, subData|
        filename = sub.filename(self.addLanguageToFile?)
        File.open(filename, 'w') { |f| f.write(subData) }
      end
    end
  end

  def search
    do_work do
      @client.searchSubtitles(@resController.movies)
      @resController.reload
    end
  end
  
  # menu items opening websites use this
  ib_action :openURL
  def openURL(sender)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(URLS[sender.tag]))
  end
  
  private
  
    # logs in, adds languages and displays current connection status.
    # TODO: 
    # - if connect fails, then let user reconnect (call this method again)
    #   and disable (or something) relevant parts of the UI.
    # - Fix handling of logged in/out state (tokens among other things).
    # - if changing to threaded api calls put those in "do_work"-block
    # - adjust error dialog's message when adding ability to reconnect
    def connect_to_server!
      @client.logIn
      add_languages(@client.languages)
      total = @client.serverInfo['subs_subtitle_files']
      @connStatus.setStringValue("Connected to OpenSubtitles.org (#{total} subtitles).")
      @connStatus.setTextColor(NSColor.blackColor)
    rescue Client::ConnectionError => e
      NSRunAlertPanel("Error connecting to server", "Problem connecting to OpenSubtitles.org's server. The error message was:\n#{e.message}", nil, nil, nil)
      @connStatus.setStringValue("Error connecting to server.")
      @connStatus.setTextColor(NSColor.redColor)
    end

    def add_languages(languages)
      languages.sort.each do |lang|
        item = NSMenuItem.alloc.initWithTitle_action_keyEquivalent(lang.name, nil, "")
        item.setRepresentedObject(lang)
        image = NSImage.imageNamed(lang.iso6391 + ".png") || NSImage.imageNamed(NO_FLAG_IMAGE)
        item.setImage(image)
        @languages.menu.addItem(item)
      end
    end
    
    def addLanguageToFile?
      @addLanguageToFile == NSOnState
    end
  
    # do "the work" in a supplied block
    def do_work
      @workingStatus.startAnimation(self)
      yield
      @workingStatus.stopAnimation(self)
    end
end
