require 'lib/simple_gui_creator'
display_frame = ParseTemplate::JFramer.new.parse_setup_string "[bug:bug]"
display_frame.elements[:bug].on_clicked { 	    SimpleGuiCreator.new_nonexisting_or_existing_filechooser_and_go "hello there" }

