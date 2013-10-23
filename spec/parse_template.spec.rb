# encoding: UTF-8
require File.dirname(__FILE__)+ '/common'

describe SimpleGuiCreator::ParseTemplate do

  def parse_string string
      @frame = SimpleGuiCreator::ParseTemplate.new
	  @frame.parse_setup_string(string)
	  @frame
  end
  
  after do
    @frame.close if @frame
  end
  
  it "should parse title lines" do
    frame = parse_string " ------------A Title-------------------------------------------"
	  frame.title.should == "A Title"
	  frame.get_title.should == "A Title" # java method mapping :)
	  frame.original_title.should == "A Title"
	  frame.title= 'new title'
	  frame.get_title.should == "new title"
	  frame.original_title.should == "A Title"
  end
  
  it "should save buttons original text" do
    frame = parse_string "|  [Setup Preferences:preferences][Start:start] [Stop:stop] |"
	frame.elements[:start].text='new text'
	frame.elements[:start].text.should == 'new text'
    frame.elements[:start].original_text.should == 'Start'
  end
  
  it "should parse button only lines, with several buttons same line" do
   frame = parse_string "|  [Setup Preferences:preferences][Start:start] [Stop:stop] |"
   get_dimentia(frame.elements[:stop]).should == [221, 10, 20, 60]
   assert frame.elements.length == 3
   prefs_button = frame.elements[:preferences]
   start_button = frame.elements[:start]
   prefs_button.text.should == "Setup Preferences"
   get_dimentia(prefs_button).should == [10, 10, 20, 139]
   assert start_button.text == "Start"
   prefs_button.text = "new text" 
   assert prefs_button.text == "new text"
   prefs_button.location.x.should_not == start_button.location.x
   prefs_button.location.y.should == start_button.location.y
   frame.get_size.height.should be > 0
   frame.get_size.width.should be > 0
  end
  
  it "should parse drop down lines" do
    for string in ["[some dropdown lines \\/:dropdown_name]", "[some dropdown lines \\/ : dropdown_name]", "[some dropdown lines\\/: dropdown_name]", "[some dropdown lines ▼ : dropdown_name]"]
      frame = parse_string string
      frame.elements[:dropdown_name].class.should ==  Java::JavaxSwing::JComboBox
      frame.elements[:dropdown_name].add_items ['a', 'b', 'c']
      frame.elements[:dropdown_name].get_item_at(0).should == 'some dropdown lines'
      frame.elements[:dropdown_name].on_select_new_element{|element, idx| p element, idx} # seems to work...
      frame.close
    end
    frame = parse_string "[\\/:dropdown_name]"
    frame.elements[:dropdown_name].get_item_at(0).should be_nil    
 end

  it "should parse text strings" do
    frame = parse_string '|  "Temp Dir location:temp_dir" |'
	  assert frame.elements.length == 1
	  frame.elements[:temp_dir].should_not be nil
  end
  
  it "should handle a string below buttons" do
    frame = parse_string <<-EOL
----------A title------------
| [a button:button] [a button2:button2] |
| "some text2:text1"                    |
---------------------------------------
  EOL
    assert frame.elements.length == 3
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
  
  it "should accept char as length" do
    frame = parse_string "| \":my_name,width=255char\""
	frame.elements[:my_name].size.width.should == 2719
    frame = parse_string "| \":my_name,width=255chars\""
	frame.elements[:my_name].size.width.should == 2719
  end
  
  it "should not add codeless items to elements" do
    frame = parse_string " \"some stuff without a code name\" "
    frame.elements.size.should == 0
  end
  
  it "should not allow unknown param settings" do
    proc { parse_string " \" text:name,fake=fake \" "}.should raise_exception
  end
  
  it "should allow mixed on the same line" do
    frame = parse_string %! "text:text", [button:button] !
	  frame.elements.size.should == 2
	  frame.elements[:button].should_not be_nil
	  frame.elements[:text].should_not be_nil
  end
  
 # LODO gets h,w of trivial text areas *wrong* oh so wrong
 # TODO you can line up stuff to get start coords for everything
 #   end sizes
 # allow prepropagation of textareas, for easier width detection...and/or separating out concerns...hmm...
 #    YAML-possible for the layout, in a separate file.  Then it's still semi-separated LOL
 #    parse_setup_string string, :text_area_to_use_text => string
 #      Make a GUI editor for editing the YAML too :P
 # single column editable text field?
 
 it "should accept height, width, abs_x, abs_y" do
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
	# TODO
	
 end
 
 it "should parse blank buttons with the extra space counting for size" do
   frame = parse_string " | [                           :text_to_use]                  |"
   button = frame.elements[:text_to_use]
   button.text.should ==  "" # torn on this one...
   button.size.width.should==129 # bigger than 35, basically
 end
 
# not yet anyway :)
# it "should parse text fields [single line text areas]" do
#   string = "[    :text_area,type=editable]  |"
#   frame = parse_string string
#	frame.elements[:text_area].class.should == Java::JavaxSwing::JTextField
# end
 
 it "should parse text areas" do
    string = <<-EOL
| [                             :text_area]                  |
| [                                       ]                  |
| [                            :text_area2]                  |
| [                                       ]                  |
    EOL
	frame = parse_string string
	frame.elements.length.should == 2 # not create fake empty buttons underneath :)
	text_area_dimentia(frame.elements[:text_area]).should == [0, 0, 48, 319] # it's "sub-contained"  in a jscrollpane so these numbers are relative to that <sigh>
	text_area_dimentia(frame.elements[:text_area2]).should == [0, 0, 48, 319] # ?? 308
 end
 
 it "should allow text area sizing" do
    string = <<-EOL
 [                             :text_area,width=155char,height=255chars] 
 [                                                                     ] 
    EOL
	frame = parse_string string	
	text_area_dimentia(frame.elements[:text_area]).should == [0, 0,  2833, 1649] # XXX is this a "perfect" height?
 end
 
 def text_area_dimentia(element)
 	element.class.should == Java::JavaxSwing::JTextArea
   # weird swing bug? it doesn't propagate size for awhile or something?
   while(get_dimentia(element) == [0,0,0,0])
     puts 'weird TextArea 0,0,0,0'
     sleep 0.2
   end
   get_dimentia(element)
 end
 
 it "should let you use ending colons" do
   frame = parse_string "\"Here's your template:\""
   frame.elements.length.should == 0 # and hope it includes the colon in there :)
 end
 
 it "should allow for spaced out attributes" do
   frame = parse_string "| [      :text, width = 200          ] "
   get_dimentia(frame.elements[:text])[3].should == 200
 end
 
 it "should allow for non symbol names" do
   frame = parse_string "[button : button]"
   frame.elements[:button].should_not be_nil
 end
 
 it "should parse text areas that aren't first, also one right next to it both sides" do
   frame = parse_string <<-EOL
   [button : button][textare : textarea]
                    [                  ]
   EOL
   text_area_dimentia(frame.elements[:textarea]).should == [0, 0, 32, 88]   
 end
 
 it "should allow for blank lines to mean spacing" do
   frame = parse_string "| [ a button] |\n [ a button] \n[ a button]"
   frame.size.height.should == 130
   frame.close
   frame = parse_string "| [ a button] |\n [ a button] \n[ a button]\n| |"
   frame.size.height.should == 155
 end
 
 it "should allow for checkboxes" do
   f = parse_string "[✓:checkbox_name]"
   checkbox = f.elements[:checkbox_name]
   got_check = false
   checkbox.after_checked { got_check = true }
   checkbox.set_checked!
   assert got_check
   got_check2 = false
   got_check3 = false
   checkbox.on_clicked { |value|
    got_check2 = true
   }
   checkbox.on_clicked {
    got_check3 = true
   }
   checkbox.click!
   assert got_check2
   assert got_check3
   checkbox.set_unchecked!
   got_check5 = false
   checkbox.after_unchecked { got_check5 = true }
   checkbox.click!
   assert got_check5 == false
   checkbox.click!
   assert got_check5
   f.close
   
   for string in ["[✓:checkbox_name]", "[✓ : checkbox_name]", "[/:checkbox_name]"] # UTF-8
     f = parse_string string
	 checkbox = f.elements[:checkbox_name]
     checkbox.class.should == Java::JavaxSwing::JCheckBox
     checkbox.get_text.should == ""
	 f.close
   end
 end
 
 it "should allow checkboxes with others" do
   f = parse_string %!"Stream to url:" [✓:stream_to_url_checkbox]   "      none:code_name,width=250" [ Set streaming url : set_stream_url ]!
   f.elements[:stream_to_url_checkbox].class.should == Java::JavaxSwing::JCheckBox
   f.elements.count.should == 3
 end

end
