# coding: UTF-8
require '../lib/simple_gui_creator'
include SimpleGuiCreator
  template = %!"Save to file:" [✓:record_to_file]!
  
  frame = ParseTemplate.new.parse_setup_string template
  frame.elements[:record_to_file].on_clicked { |new_value|
  
  }
