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
  URLS = ['http://www.opensubtitles.org', 'http://www.opensubtitles.org/upload', 'http://code.google.com/p/undertext']
  FILES = ['License.rtf', 'Acknowledgments.rtf']
  DEFAULTS = { 'authEnabled' => false, 'username' => '', 'addLanguageToFile' => false }
  NON_LANGUAGE_ITEMS = 2

  ib_outlets :resController, :infoController, :prefController
  ib_outlets :mainWindow, :connStatus, :workingStatus, :languages
  
  # TODO: open recent in app menu
  def init
    super_init
    @client = nil
    NSUserDefaults.standardUserDefaults.registerDefaults(DEFAULTS)
    self
  end
  
  def awakeFromNib
    @workingStatus.setUsesThreadedAnimation(true) # todo: remove if changing to threaded api-calls
    @mainWindow.makeKeyAndOrderFront(nil)
    @mainWindow.setExcludedFromWindowsMenu(true)
  end
  
  def applicationWillFinishLaunching(notification)
    reconnect(nil)
  end
  
  def applicationShouldHandleReopen_hasVisibleWindows(app, visibleWindows)
    @mainWindow.makeKeyAndOrderFront(nil) unless visibleWindows
    false # means NSApplication won't try to make a new untitled document
  end
  
  def applicationWillTerminate(notification)
    # todo: save user defaults
  end
  
  # Automatically called. Returns boolean for menu item's enabled state.
  def validateMenuItem(item)
    case item.action
    when 'toggleInfoWindow:'
      item.setTitle(@infoController.window.isVisible ? "Hide Info" : "Show Info")
      true
    else
      true
    end
  end
  
  # logs in, adds languages and displays current connection status.
  # todo: call "search" if needed
  ib_action :reconnect
  def reconnect(sender)
    status("Connecting...")
    username, password = @prefController.authentication
    clientWork do
      @client.logOut if @client
      @client = Client.new(username, password)
      @infoController.defaultInfo = @client.serverInfo
      add_languages(@client.languages) if @languages.numberOfItems == NON_LANGUAGE_ITEMS
    end
    status("Connected to OpenSubtitles.org as #{@client.user}")
  end
  
  ib_action :showMainWindow
  def showMainWindow(sender)
    @mainWindow.makeKeyAndOrderFront(nil)
  end
  
  ib_action :toggleInfoWindow
  def toggleInfoWindow(sender)
    if @infoController.window.isVisible
      @infoController.close
    else
      @infoController.showWindow(nil)
    end
  end
  
  # for folders it searches recursively for movie files
  def application_openFiles(sender, paths)
    files, folders = paths.partition { |path| File.file? path }
    folders.each do |folder|
      files += Dir.glob(folder + "/**/*.{#{EXTS.join(',')}}")
    end
    movies = files.map { |file| Movie.alloc.initWithFile(file, @resController) }
    @resController.add_movies(movies)
    search(movies) # populate outline with search results
  end
  
  # Can choose directory and/or multiple files (movies)
  def open(sender)
    open = NSOpenPanel.openPanel
    open.setAllowsMultipleSelection(true)
    open.setCanChooseDirectories(true)
    open.beginSheetForDirectory_file_types_modalForWindow_modalDelegate_didEndSelector_contextInfo(
      nil, nil, ["public.movie"], @mainWindow, self,
      'openPanelDidEnd:returnCode:contextInfo:', nil
    )
  end
  
  def openPanelDidEnd_returnCode_contextInfo(sender, result, context)
    application_openFiles(nil, sender.filenames) if result == NSOKButton
  end

  # todo: handle if file already exists (suffix with number or ask)
  ib_action :downloadSelected  
  def downloadSelected(sender)
    clientWork do
      @client.downloadSubtitles(@resController.downloads) do |sub, subData|
        filename = sub.filenameWithLanguage(NSUserDefaults.standardUserDefaults.boolForKey('addLanguageToFile'))
        File.open(filename, 'w') { |f| f.write(subData) }
      end
    end
  end

  def search(movies)
    clientWork do
      @client.searchSubtitles(movies)
      @client.movieDetails(movies)
      @resController.reloadData
    end
  end
  
  # menu items opening websites use this
  ib_action :openURL
  def openURL(sender)
    NSWorkspace.sharedWorkspace.openURL(NSURL.URLWithString(URLS[sender.tag]))
  end
  
  # Show license and acknowledgements
  ib_action :openFile
  def openFile(sender)
    NSWorkspace.sharedWorkspace.openFile(NSBundle.mainBundle.resourcePath + "/" + FILES[sender.tag])
  end
  
  private

    def add_languages(languages)
      languages.sort.each do |lang|
        item = NSMenuItem.alloc.initWithTitle_action_keyEquivalent(lang.name, nil, "")
        item.setRepresentedObject(lang)
        item.setImage(lang.image)
        @languages.menu.addItem(item)
      end
      @languages.setEnabled(true)
    end
  
    # TODO: describe method
    def clientWork
      @workingStatus.setHidden(false)
      @workingStatus.startAnimation(self)
      yield
    rescue Client::ResultError => e
      error_status(e.message) # TODO: special case if log in credentials wrong
    rescue Client::ConnectionError => e
      error_status(e.message)
    ensure
      @workingStatus.stopAnimation(self)
      @workingStatus.setHidden(true)
    end
    
    def status(msg)
      @connStatus.setStringValue(msg)
      @connStatus.setTextColor(NSColor.blackColor)
    end
    
    # TODO: Check english language for errors and correct them
    def error_status(msg)
      @connStatus.setStringValue(msg)
      @connStatus.setTextColor(NSColor.redColor)
      NSRunAlertPanel(msg, "Please check your internet connection and www.opensubtitles.org before trying again.", nil, nil, nil)
    end
end
