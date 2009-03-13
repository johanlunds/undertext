require 'rubygems'
require 'rake'
require 'osx/cocoa'

INFO = OSX::NSMutableDictionary.dictionaryWithContentsOfFile('Info.plist')

def pkg_path
  File.expand_path("~/Desktop/#{INFO["CFBundleExecutable"]}-#{INFO["CFBundleVersion"]}.dmg")
end

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
  File.delete(pkg_path) if File.exists?(pkg_path)
  sh "hdiutil create -volname '#{app_name}' -srcfolder 'build/Release/#{app_name}.app' '#{pkg_path}'"
end

task :release => :package do
  sig = `ruby bin/sign_update.rb #{pkg_path} dsa_priv.pem`
  
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