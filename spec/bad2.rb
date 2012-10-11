# coding: UTF-8
require '../lib/simple_gui_creator'
include SimpleGuiCreator
  template = <<-EOL
  ------------ Recording Options -------------
  "Save to file:" [✓:record_to_file]
  EOL
  frame = ParseTemplate.new.parse_setup_string template
  frame.elements[:record_to_file].on_clicked { |new_value|
    storage['record_to_file'] = new_value
	reset_options_frame
  }
