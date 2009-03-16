= Undertext for Mac OS X =

Application for downloading subtitles for your movies and tv episodes using
OpenSubtitles.org.

The searching is done by calculating a hash for every movie file and then looking
in OpenSubtitles.org's database for matching subtitles. This way you find matching
subtitles quickly and can be sure they'll be correctly sync'ed with the video.

Undertext is made for Mac OS X using it's Cocoa so it integrates very well with
the system. Undertext is very simple and intuitive to use and install. Compared
to using the browser this is a very quick and comfortable way to get your
subtitles.

*Homepage:* http://code.google.com/p/undertext. There you can find downloads, get
the source code, submit bugs, suggest new features and get more information.

This app wouldn't be possible without OpenSubtitles.org. Thanks! Also see
Credits.rtf for more acknowledgements.

== Requirements ==

 * Mac OS X (I use Leopard, haven't tried on Tiger and earlier versions)
 * RubyCocoa (already installed in new OS X versions)
 * For developing: Xcode (I use version 3)

== Installation and Usage ==

Download the latest version from the homepage, or build from source using 
Xcode or by running `rake package` (only works with a SVN working copy) in the
terminal. Open the dmg-file and copy the bundled `.app` into your
Applications-folder.

Launch Undertext.app with movie files or/and folders and it'll search for subtitles.
You can also open files by selecting "Open..." in the application menu.

== Copyright and License ==

Copyright (c) 2009 Johan Lundström. Released as open source under the BSD license,
see LICENSE.txt.