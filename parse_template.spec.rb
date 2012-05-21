require 'rubygems'
require 'rspec/autorun'
require 'sane' # gem

require 'parse_template.rb'
describe ParseTemplate do

  def parse_string string
    ParseTemplate.parse_string string
  end
  it "should parse titles" do
    frame = parse_string " ------------A Title-------------------------------------------"
	frame.get_title.should == "A Title"
  end
  
  it "should parse button only lines" do
   frame = parse_string "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |"
   assert frame.buttons.length == 3
   frame.buttons['preferences'].text.should == "Setup Preferences"
   assert frame.buttons['start'].text == "Start"
   frame.buttons['preferences'].text = "new text" 
   assert frame.buttons['preferences'].text == "new text"
   frame.buttons['preferences'].location.x.should_not == frame.buttons['start'].location.x
   frame.buttons['preferences'].location.y.should == frame.buttons['start'].location.y
   frame.get_size.height.should be > 0
   frame.get_size.width.should be > 0
  end
  
#  it "should parse drop down lines"
#    frame = parse_string "| [some dropdown lines:dropdowns \/] |"
# end

  it "should parse text strings" do
    frame = parse_string "|  <<Temp Dir location:temp_dir>> |"
	assert frame.buttons.length == 1
	frame.buttons['temp_dir'].should_not be nil
  end
  
  it "should genuinely work" do
  frame = parse_string <<-EOL
----------A title------------
| [a button:button] [a button2:button2] |
| <<some text2:text1>>                  |
-----------------------
  EOL
  assert frame.buttons.length == 3
  frame.buttons['button'].on_clicked {
    p 'button clicked'
  }
  frame.show
  end

end
