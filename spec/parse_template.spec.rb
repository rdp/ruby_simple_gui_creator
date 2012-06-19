require File.dirname(__FILE__)+ '/common'

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
	frame.title.should == "A Title"
	frame.get_title.should == "A Title" # java method mapping :)
	frame.original_title.should == "A Title"
	frame.title= 'new title'
	frame.get_title.should == "new title"
	frame.original_title.should == "A Title"
  end
  
  it "should parse button only lines" do
   frame = parse_string "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |"
   assert frame.elements.length == 3
   prefs_button = frame.elements[:preferences]
   start_button = frame.elements[:start]
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
    frame = parse_string '|  "Temp Dir location:temp_dir" |'
	assert frame.elements.length == 1
	frame.elements[:temp_dir].should_not be nil
  end
  
  it "should work with real instance" do
    frame = parse_string <<-EOL
----------A title------------
| [a button:button] [a button2:button2] |
| "some text2:text1"                    |
---------------------------------------
  EOL
    assert frame.elements.length == 3
    frame.elements[:button].on_clicked {
      p 'button clicked'
    }
    frame.show
  end
  
  it "should split escaped colons" do
    frame = parse_string "| \"some stuff ::my_name\""
	frame.elements[:my_name].text.should == 'some stuff :'
  end
  
  it "should not accept zero length strings without width spec" do  
    proc {frame = parse_string "| \":my_name\""}.should raise_exception
  end
  
  it "should accept zero length strings if they have a width spec" do
    frame = parse_string "| \":my_name,width=250\""
	frame.elements[:my_name].text.should == ''
  end
  
  it "should not add codeless items to elements" do
    frame = parse_string " \"some stuff without a code name\" "
    frame.elements.size.should == 0
  end
  
  it "should not allow unknown param settings" do
    proc { parse_string " \" text:name,fake=fake \" "}.should raise_exception
  end
  
 # LODO allow blank lines as extra spacing
 # LODO allow internal sub-boxes LOL
 # TODO mixeds on the same line
 # LODO should pass the button through to on_clicked [?] or button with frame, too?
 # LODO should be able to clear everything a button does or used to do...
 # LODO a 'title managing' object LOL
 # LODO rel_width=+100 or some odd
 # buttons should require a name :P
 
 it "should accept height, width, x, y" do
   frame = parse_string ' [a:my_name,abs_x=1,abs_y=2,width=100,height=101] '
   get_dimentia(frame.elements[:my_name]).should == [1,2,101,100]
 end
 
 it "should accept params, without a name" do
   frame = parse_string ' "a:abs_x=1,abs_y=1,width=100,height=100" '
   frame.elements.should be_empty
 end
 
 it "should allow for symbol access" do
   frame = parse_string '| "a:my_name" |'
   frame.elements[:my_name].text.should == 'a'
 end
 
 it "should do rstrip on symbol names" do
   frame = parse_string '| "a:my_name " |'
   frame.elements[:my_name].text.should == 'a'
 end
 
 it "should disallow double names...I think so anyway..." do
    proc { frame = parse_string('| "a:my_name" |\n'*2) }.should raise_exception
 end
 
 def get_dimentia(element)
   x = element.get_location.x
   y = element.get_location.y
   h = element.size.height
   w = element.size.width
   [x,y,h,w]
 end
 
 it "should line up elements right when given some abs" do
    frame = parse_string <<-EOL 
| [a button:button_name,width=100,height=100,abs_x=50,abs_y=50] [a third button:third]
| [another button:button_name2] [another button:button_name4]|
| [another button:button_name3] |
    EOL
	get_dimentia(frame.elements[:button_name]).should == [50,50,100,100]
	#assert_matches_dimentia(frame.elements[:third], 
	
 end
	

end
