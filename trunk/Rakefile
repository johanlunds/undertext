require 'rubygems'
require 'rake'
require 'osx/cocoa'

INFO = OSX::NSMutableDictionary.dictionaryWithContentsOfFile('Info.plist')

def pkg_path
  File.expand_path("~/Desktop/#{INFO["CFBundleExecutable"]}-#{INFO["CFBundleVersion"]}.dmg")
end

desc "Release by default"
task :default => :release

desc "Build project in Xcode"
task :build do
  sh "xcodebuild -configuration Release build"
end

desc "Update Info.plist with current SVN revision"
task :update_version do
  new_version = INFO["CFBundleVersion"] = INFO["CFBundleShortVersionString"] + "." + `svn info`[/Revision: (\d+)/, 1]
  INFO.writeToFile_atomically('Info.plist', true)
  puts "New version: #{new_version}"
end

desc "Build and package app as DMG"
task :package => [:update_version, :build] do
  app_name = INFO["CFBundleExecutable"]
  File.delete(pkg_path) if File.exists?(pkg_path)
  sh "hdiutil create -volname '#{app_name}' -srcfolder 'build/Release/#{app_name}.app' '#{pkg_path}'"
end

desc "Build, package and generate info for appcast"
task :release => :package do
  sig = `openssl dgst -sha1 -binary < '#{pkg_path}' | openssl dgst -dss1 -sign dsa_priv.pem | openssl enc -base64`
  
  puts
  puts "Todo list"
  puts "=========="
  puts "1. upload packaged app"
  puts "2. update release notes"
  puts "3. add item to appcast"
  puts "4. commit release notes and appcast"
  puts "5. tag current release in SVN. Done!"
  puts
  puts "Appcast item info"
  puts "=========="
  puts "Filesize: #{File.size(pkg_path)}"
  puts "RFC2822 time: #{Time.now.strftime("%a, %d %b %G %T %z")}"
  puts "Signature: #{sig}"
end