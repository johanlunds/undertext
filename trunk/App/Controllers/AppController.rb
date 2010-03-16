#
#  AppController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

class AppController < NSObject
  
  # Used if looking by UTI is too cumbersome
  MOVIE_EXTS = %w(avi mpg mpeg wmv asf divx mov m2p moov omf qt rm dv 3ivx mkv ogm mp4 m4v)
  URLS = ['http://www.opensubtitles.org', 'http://www.opensubtitles.org/upload', 'http://code.google.com/p/undertext']
  FILES = ['License.rtf', 'Acknowledgments.rtf']
  DEFAULTS = { 'authEnabled' => false.to_ns, 'username' => ''.to_ns }

  ib_outlets :resController, :detailsController, :prefController
  ib_outlets :mainWindow, :connStatus, :workingStatus, :languages
  
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
    when 'toggleDetailsWindow:'
      item.setTitle(@detailsController.window.isVisible ? "Hide Details" : "Show Details")
      true
    else
      true
    end
  end
  
  ib_action :showMainWindow
  def showMainWindow(sender)
    @mainWindow.makeKeyAndOrderFront(nil)
  end
  
  ib_action :toggleDetailsWindow
  def toggleDetailsWindow(sender)
    if @detailsController.window.isVisible
      @detailsController.close
    else
      @detailsController.showWindow(nil)
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
  
  # it searches folders recursively for movie files
  def application_openFiles(sender, paths)
    files, folders = paths.partition { |path| File.file? path }
    folders.each { |folder| files += Dir.glob(folder + "/**/*.{#{MOVIE_EXTS.join(',')}}") }
    movies = files.map { |file| Movie.alloc.initWithFile(file) }
    @resController.add_movies(movies)
    search(movies)
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
  
  # logs in, adds languages and displays current connection status.
  # todo: call "search" if needed
  ib_action :reconnect
  def reconnect(sender)
    @client = Client.new(*@prefController.credentials)
    finished = client_working do
      @client.logIn
      @detailsController.defaultInfo = @client.serverInfo
      add_languages(@client.languages) unless @languages.isEnabled
    end
    status("Connected to OpenSubtitles.org as #{@client.user}") if finished
  end

  def search(movies)
    client_working do
      @client.searchSubtitles(movies)
      @client.movieDetails(movies)
    end
    @resController.reloadData
  end

  ib_action :downloadSelected  
  def downloadSelected(sender)
    client_working do
      @client.downloadSubtitles(@resController.downloads)
      @downloaded_subs = @resController.downloads
      writeSubtitleContents
    end
  end
  
  # Will write all subtitles in @downloaded_subs to disk and ask if the
  # file already exists.
  def writeSubtitleContents
    return unless sub = @downloaded_subs.pop
    
    if File.exists?(sub.filename)
      NSBeginCriticalAlertSheet(
        "The file \"#{File.basename(sub.filename)}\" already exists. Do you want to replace it?",
        "Replace", "Don't Replace", nil, @mainWindow, self, nil, 'overwriteSheetDidDismiss:returnCode:contextInfo:', sub,
        "If replaced the current contents will be lost. The folder path is \"#{File.dirname(sub.filename)}\"."
      )
    else
      File.open(sub.filename, 'w') { |f| f.write(sub.contents) }
      writeSubtitleContents
    end
  end
  
  def overwriteSheetDidDismiss_returnCode_contextInfo(sender, result, context)
    # context is ObjcPtr and argument is an "Objective-C type encoding"
    sub = context.cast_as("@")
    File.open(sub.filename, 'w') { |f| f.write(sub.contents) } if result == NSAlertDefaultReturn
    writeSubtitleContents
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
  
    # Will animate progress indicator during execution of passed block.
    # Catches exceptions and if so updates status and returns false.
    def client_working
      @workingStatus.startAnimation(self)

      begin
        yield
      rescue Client::ConnectionError => e
        error_status(e.message)
        return false
      ensure
        @workingStatus.stopAnimation(self)
      end
      
      true
    end
    
    def status(msg)
      @connStatus.setStringValue(msg)
      @connStatus.setTextColor(NSColor.blackColor)
    end
    
    def error_status(msg)
      @connStatus.setStringValue("Server communication error")
      @connStatus.setTextColor(NSColor.redColor)
      NSRunAlertPanel("An error occured while communicating with the server.", msg, nil, nil, nil)
    end
end
