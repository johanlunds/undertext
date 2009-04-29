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
  FILES = ['License.rtf', 'Acknowledgements.rtf']
  DEFAULTS = { 'authEnabled' => false, 'username' => '' }
  NON_LANGUAGE_ITEMS = 2

  ib_outlets :resController, :infoController, :prefController
  ib_outlets :mainWindow, :connStatus, :workingStatus, :languages, :addLanguage
  
  def init
    super_init
    @client = Client.new
    NSUserDefaults.standardUserDefaults.registerDefaults(DEFAULTS)
    self
  end
  
  def awakeFromNib
    @workingStatus.setUsesThreadedAnimation(true) # todo: remove if changing to threaded api-calls
    @mainWindow.makeKeyAndOrderFront(nil)
    @mainWindow.setExcludedFromWindowsMenu(true)
  end
  
  def applicationWillFinishLaunching(notification)
    connectToServer(nil)
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
  # todo: if changing to threaded api calls put those in "do_work"-block
  # todo: call "search"
  # todo: logout before logging in?
  ib_action :connectToServer
  def connectToServer(sender)
    status("Connecting...")
    username, password = @prefController.authentication
    @client.logIn(username, password)
    add_languages(@client.languages) if @languages.numberOfItems == NON_LANGUAGE_ITEMS
    total = @client.serverInfo['subs_subtitle_files']
    status("Connected to OpenSubtitles.org (#{total} subtitles)")
  rescue Client::ConnectionError => e
    error_status("Error when connecting to server", "Please check your internet connection and/or www.opensubtitles.org before trying to reconnect.\nError message: #{e.message}")
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
  # todo: this won't execute if connection error at startup
  # todo: refactor adding of files/movies to outline
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
    do_work do
      @client.downloadSubtitles(@resController.downloads) do |sub, subData|
        filename = sub.filename(@addLanguage.state == NSOnState)
        File.open(filename, 'w') { |f| f.write(subData) }
      end
    end
  rescue Client::ConnectionError => e
    error_status("Error when downloading", "Please check your internet connection and/or www.opensubtitles.org before trying again.\nError message: #{e.message}")
  end

  def search(movies)
    do_work do
      @client.searchSubtitles(movies)
      @client.movieDetails(movies)
      @resController.reloadData
    end
  rescue Client::ConnectionError => e
    error_status("Error when searching", "Please check your internet connection and/or www.opensubtitles.org. A search will be automatically done next time you reconnect.\nError message: #{e.message}")
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
  
    # do "the work" in a supplied block
    # todo: if exception in yield animation will keep going
    def do_work
      @workingStatus.startAnimation(self)
      yield
      @workingStatus.stopAnimation(self)
    end
    
    def status(msg)
      @connStatus.setStringValue(msg)
      @connStatus.setTextColor(NSColor.blackColor)
    end
    
    def error_status(msg, longer_msg)
      @connStatus.setStringValue(msg)
      @connStatus.setTextColor(NSColor.redColor)
      NSRunAlertPanel(msg, longer_msg, nil, nil, nil)
    end
end
