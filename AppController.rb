#
#  AppController.rb
#  Undertext
#
#  Created by Johan Lundström on 2009-01-28.
#  Copyright (c) 2009 Johan Lundström.
#

class AppController < NSWindowController
  
  # Used if looking by UTI is too cumbersome
  EXTS = %w(3g2 3gp 3gp2 3gpp 60d ajp asf asx avchd avi bik bix box cam dat divx 
    dmf dv dvr-ms evo flc fli flic flv flx gvi gvp h264 m1v m2p m2ts m2v m4e m4v
    mjp mjpeg mjpg mkv moov mov movhd movie movx mp4 mpe mpeg mpg mpv mpv2 mxf
    nsv nut ogg ogm omf ps qt ram rm rmvb swf ts vfw vid video viv vivo vob vro
    wm wmv wmx wrap wvx wx x264 xvid)

  attr_accessor :addLanguageToFile
  ib_outlets :outline, :status, :downloadStatus, :selectedCount
  
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
  
  def addLanguageToFile
    @addLanguageToFile == NSOnState
  end
  
  # for folders it searches recursively for movie files
  def application_openFiles(sender, paths)
    files, folders = paths.partition { |path| File.file? path }
    folders.each do |folder|
      files += Dir.glob(folder + "/**/*.{#{EXTS.join(',')}}")
    end
    @outline.dataSource.setFiles(files)
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
      self.window,
      self,
      'openPanelDidEnd:returnCode:contextInfo:',
      nil
    )
  end
  
  def openPanelDidEnd_returnCode_contextInfo(sender, result, context)
    application_openFiles(nil, sender.filenames) if result == NSOKButton
  end

  # todo: handle if file already exists (suffix with number or ask)
  ib_action :downloadSelected  
  def downloadSelected(sender)
    return # todo: implement Client#downloadSubtitles and ResultsController#subsToDownload
    @client.downloadSubtitles(@outline.dataSource.subsToDownload) do |sub, subData|
      # Calculate filename for subfile
      filename = sub.movie.filename
      path = filename.chomp(File.extname(filename))
      path += ".#{sub.info["SubLanguageID"]}" if self.addLanguageToFile
      path += ".#{sub.info["SubFormat"]}"
      # ... and save to file
      File.open(path, 'w') { |f| f.write(subData) }
    end
  end

  def search
    # todo: show returned count of results
    @client.searchSubtitles(@outline.dataSource.movies)
  end
end
