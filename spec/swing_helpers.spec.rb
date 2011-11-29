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
      "a/b/c".to_filename.should == File.expand_path("a\\b\\c")
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
  
  end

end
puts 'close the windows...'
