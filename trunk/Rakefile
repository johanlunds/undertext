require 'rubygems'
require 'rake'
require 'osx/cocoa'

PRIVATE_KEY_FILE = "dsa_priv.pem"
INFO = OSX::NSMutableDictionary.dictionaryWithContentsOfFile('Info.plist')
PKG_PATH = File.expand_path("~/Desktop/#{INFO["CFBundleExecutable"]}-%s.dmg") # interpolate version

task :default => :release

task :build do
  sh "xcodebuild -configuration Release build"
end

task :update_version do
  new_version = INFO["CFBundleVersion"] = INFO["CFBundleShortVersionString"] + "." + `svn info`[/Revision: (\d+)/, 1]
  INFO.writeToFile_atomically('Info.plist', true)
  puts "New version: #{new_version}"
end

task :package => [:update_version, :build] do
  app_name = INFO["CFBundleExecutable"]
  pkg_path = PKG_PATH % INFO["CFBundleVersion"]
  File.delete(pkg_path) if File.exists?(pkg_path)
  sh "hdiutil create -volname '#{app_name}' -srcfolder 'build/Release/#{app_name}.app' '#{pkg_path}'"
end

task :release => :package do
  pkg_path = PKG_PATH % INFO["CFBundleVersion"]
  sig = `ruby bin/sign_update.rb #{pkg_path} #{PRIVATE_KEY_FILE}`
  
  puts
  puts "Todo list"
  puts "=========="
  puts "1. upload packaged app"
  puts "2. update release notes"
  puts "3. add item to appcast"
  puts "4. commit release notes and appcast. Done!"
  puts
  puts "Appcast item info"
  puts "=========="
  puts "Filesize: #{File.size(pkg_path)}"
  puts "RFC2822 time: #{Time.now.strftime("%a, %d %b %G %T %z")}"
  puts "Signature: #{sig}"
end