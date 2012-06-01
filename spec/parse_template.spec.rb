require File.dirname(__FILE__)+ '/common'

require 'parse_template.rb'
require 'swing_helpers.rb'

describe ParseTemplate do

  def parse_string string
    @frame = ParseTemplate::JFramer.new
	@frame.parse_setup_string(string)
	@frame
  end
  
  after do
    @frame.close if @frame
  end
  
  it "should parse titles" do
    frame = parse_string " ------------A Title-------------------------------------------"
	frame.get_title.should == "A Title"
	frame.original_title.should == "A Title"
	frame.title= 'new title'
	frame.get_title.should == "new title"
	frame.original_title.should == "A Title"
  end
  
  it "should parse button only lines" do
   frame = parse_string "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |"
   assert frame.elements.length == 3
   prefs_button = frame.elements['preferences']
   start_button = frame.elements['start']
   prefs_button.text.should == "Setup Preferences"
   assert start_button.text == "Start"
   prefs_button.text = "new text" 
   assert prefs_button.text == "new text"
   prefs_button.location.x.should_not == start_button.location.x
   prefs_button.location.y.should == start_button.location.y
   frame.get_size.height.should be > 0
   frame.get_size.width.should be > 0
  end
  
#  it "should parse drop down lines"
#    frame = parse_string "| [some dropdown lines:dropdowns \/] |"
# end

  it "should parse text strings" do
    frame = parse_string "|  \"Temp Dir location:temp_dir\" |"
	assert frame.elements.length == 1
	frame.elements['temp_dir'].should_not be nil
  end
  
  it "should work with real instance" do
    frame = parse_string <<-EOL
----------A title------------
| [a button:button] [a button2:button2] |
| "some text2:text1"                  |
-----------------------
  EOL
    assert frame.elements.length == 3
    frame.elements['button'].on_clicked {
      p 'button clicked'
    }
    frame.show
  end
  
  it "should split escaped colons" do
    frame = parse_string "| \"some stuff ::my_name\""
	frame.elements['my_name'].text.should == 'some stuff :'
  end
  
  it "should not accept zero length strings without width spec" do  
    proc {frame = parse_string "| \":my_name\""}.should raise_exception
  end
  
  it "should accept zero length strings with width spec" do
    frame = parse_string "| \":my_name,250\""
	frame.elements['my_name'].text.should == ''
  end
end
