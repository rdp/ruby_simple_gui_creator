=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end
require File.expand_path(File.dirname(__FILE__) + '/common')
require_relative '../swing_helpers'

module SwingHelpers
 describe 'functionality' do

  it "should close its modeless dialog" do
   
   dialog = NonBlockingDialog.new("Is this modeless?")
   dialog = NonBlockingDialog.new("Is this modeless?\nSecond lineLL")
   dialog = NonBlockingDialog.new("Is this modeless?\nSecond lineLL\nThird line too!")
   dialog = NonBlockingDialog.new("Can this take very long lines of input, like super long?")
   #dialog.dispose # should get here :P
   # let user close it :P
  end
  
  it "should be able to convert filenames well" do
    if OS.windows?
      "a/b/c".to_filename.should == File.expand_path("a\\b\\c").gsub('/', "\\")
    else
      "a/b/c".to_filename.should == File.expand_path("a/b/c")
    end
  end

  it "should reveal a file" do
    FileUtils.touch "a b"
    SwingHelpers.show_in_explorer "a b"
    Dir.mkdir "a dir" unless File.exist?('a dir')
    SwingHelpers.show_in_explorer "a dir"
  end

  it "should reveal a url" do
    SwingHelpers.open_url_to_view_it_non_blocking "http://www.google.com"
  end
  
  it "should select folders" do
    raise unless File.directory?(c = SwingHelpers.new_existing_dir_chooser_and_go('hello', '.'))
    p c
    raise unless File.directory?(c = SwingHelpers.new_existing_dir_chooser_and_go)
    p c
  end

  it "should select nonexisting" do
    name = JFileChooser.new_nonexisting_filechooser_and_go 'should allow selecting nonexisting filename, try to select nonexist'
    raise if File.exist? name
    #name = SwingHelpers.SwingHelpers.new_existing_dir_chooser_and_go 'should force select existing dir, try to select nonexist'
    #raise unless File.exist? name
    name = SwingHelpers.new_previously_existing_file_selector_and_go 'shoudl forc select existing file, try to select nonexist'
    raise unless File.exist? name # it forced them to retry 
  end
  
  it "should show onminimize" do
    a = JFrame.new 'minimize me'
    a.set_size 200,200
    a.on_minimized {
      puts 'minimized'
	  a.close
	  a.dispose
    }
	a.show
  end

  it "should have an after_close method" do
    a = JFrame.new 'close me'
    a.set_size 200,200
	a.after_closed {
	  puts 'after closed'
	}
    a.show	
  end

 end
end

puts 'close the windows...'
