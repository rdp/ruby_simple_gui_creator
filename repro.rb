require 'rubygems'
#require 'lib/simple_gui_creator'
require 'java'
java_import javax.swing.JFileChooser


   class JFileChooser
    # also set_current_directory et al...
    
    # raises on failure...
    def go show_save_dialog_instead = false
      if show_save_dialog_instead
        success = show_save_dialog nil
      else
        success = show_open_dialog nil
      end
      unless success == Java::javax::swing::JFileChooser::APPROVE_OPTION
        java.lang.System.exit 1 # kills background proc...but we shouldn't let them do stuff while a background proc is running, anyway
      end
      get_selected_file.get_absolute_path
    end
	end

module SimpleGuiCreator

    # choose a file that may or may not exist yet...
    def self.new_nonexisting_or_existing_filechooser_and_go title = nil, default_dir = nil, default_filename = nil # within JFileChooser class for now...
      out = JFileChooser.new
      if default_dir
        out.set_current_directory JFile.new(default_dir)
      end
      if default_filename
        out.set_file default_filename
      end
      out.go true
	  
    end
	end
	

begin
SimpleGuiCreator.new_nonexisting_or_existing_filechooser_and_go "hello there"
rescue => e
puts 'here2'
raise
end
puts 'here1'