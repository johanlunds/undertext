require 'rubygems'
require 'rake'
require 'osx/cocoa'

INFO_PLIST = OSX::NSMutableDictionary.dictionaryWithContentsOfFile('Info.plist')
APP = INFO_PLIST["CFBundleExecutable"]
APP_VERSION = INFO_PLIST["CFBundleVersion"]

task :default => :package

task :build do
  sh "xcodebuild -configuration Release build"
end

task :package => :build do
  path = File.expand_path("~/Desktop/#{APP}-#{APP_VERSION}.dmg")
  File.delete(path) if File.exists? path
  sh "hdiutil create -volname '#{APP}' -srcfolder 'build/Release/#{APP}.app' '#{path}'"
end

task :update_version do
  new_version = INFO_PLIST["CFBundleShortVersionString"] + "." + `svn info`[/Revision: (\d+)/, 1]
  INFO_PLIST["CFBundleVersion"] = new_version
  INFO_PLIST.writeToFile_atomically('Info.plist', true)
  puts "New version: #{new_version}"
end