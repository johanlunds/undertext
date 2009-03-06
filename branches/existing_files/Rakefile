require 'rubygems'
require 'rake'
require 'osx/cocoa'

task :default => :package

task :build do
  sh "xcodebuild -configuration Release build"
end

task :package => :build do
  info = info_plist
  app = info["CFBundleExecutable"]
  version = info["CFBundleVersion"]
  path = File.expand_path("~/Desktop/#{app}-#{version}.dmg")
  File.delete(path) if File.exists? path
  sh "hdiutil create -volname '#{app}' -srcfolder 'build/Release/#{app}.app' '#{path}'"
end

task :update_version do
  info = info_plist
  new_version = info["CFBundleShortVersionString"] + "." + `svn info`[/Revision: (\d+)/, 1]
  info["CFBundleVersion"] = new_version
  info.writeToFile_atomically('Info.plist', true)
  puts "New version: #{new_version}"
end

def info_plist
  OSX::NSMutableDictionary.dictionaryWithContentsOfFile('Info.plist')
end