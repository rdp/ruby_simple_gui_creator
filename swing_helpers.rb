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
require 'java'
require 'sane' # gem
module SwingHelpers 
  
 include_package 'javax.swing'
 [JProgressBar, JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox, JDialog, SwingUtilities, JSlider] # grab these constants (http://jira.codehaus.org/browse/JRUBY-5107)
 include_package 'java.awt'
 [FlowLayout, Font, BorderFactory, BorderLayout]
 include_class java.awt.event.ActionListener
 JFile = java.io.File
 include_class java.awt.FileDialog
 include_class java.lang.System
 UIManager

 class JOptionPane
    JOptionReturnValuesTranslator = {0 => :yes, 1 => :no, 2 => :cancel, -1 => :exited}
    
    # accepts :yes => "yes text", :no => "no text"
    # returns  :yes :no :cancel or :exited
    # you must specify text for valid options.
    # example, if you specify :cancel => 'cancel' then it won't raise if they cancel
    # raises if they select cancel or exit, unless you pass in :exited => true as an option
    def self.show_select_buttons_prompt message, names_hash = {}
      names_hash[:yes] ||= 'Yes'
      names_hash[:no] ||= 'No'
      # ok ?
      old = ['no', 'yes', 'ok'].map{|name| 'OptionPane.' + name + 'ButtonText'}.map{|name| [name, UIManager.get(name)]}
      if names_hash[:yes]
        UIManager.put("OptionPane.yesButtonText", names_hash[:yes])
      end
      if names_hash[:no]
        UIManager.put("OptionPane.noButtonText", names_hash[:no])
      end
      # if names_hash[:ok] # ???
      #   UIManager.put("OptionPane.okButtonText", names_hash[:ok])
      # end
      if names_hash[:cancel]
        UIManager.put("OptionPane.noButtonText", names_hash[:cancel])
      end
      title = message.split(' ')[0..5].join(' ')
      returned = JOptionPane.showConfirmDialog nil, message, title, JOptionPane::YES_NO_CANCEL_OPTION
      old.each{|name, old_setting| UIManager.put(name, old_setting)}
      out = JOptionReturnValuesTranslator[returned]
      if !out || !names_hash.key?(out)
        raise 'canceled or exited:' + out.to_s
      end
      out
    end
    
end

 class JButton
   def initialize *args
    super *args
    set_font Font.new("Tahoma", Font::PLAIN, 11)
   end
  
   def on_clicked &block
     raise unless block
     @block = block
     add_action_listener do |e|
       begin
         block.call
       rescue Exception => e
         puts "got fatal exception thrown in button [canceled] #{e} #{e.class} #{e.backtrace[0]}"
         if $VERBOSE
          puts e.backtrace, e
         end
       end        
     end
     self
   end
  
   def simulate_click
     @block.call
   end
  
   def tool_tip= text
      if text
       text = "<html>" + text + "</html>"
       text = text.gsub("\n", "<br/>")
     end
     self.set_tool_tip_text text   
   end
  
 end

 ToolTipManager.sharedInstance().setDismissDelay(10000)

 class JFrame
  
   def close
     dispose # sigh
   end
  
   def bring_to_front # kludgey...but said to work for swing apps
    java.awt.EventQueue.invokeLater{
      setVisible(true); # unminimize
      toFront();
      repaint();
    }      
   end
  
  end
  
  def self.open_url_to_view_it_non_blocking url
      raise unless url =~ /^http/i
      if OS.windows?
        system("start #{url.gsub('&', '^&')}") # LODO would launchy help/work here with the full url?
      else
        system "#{OS.open_file_command} \"#{url}\""
        sleep 2 # disallow exiting immediately after...LODO
      end
    end
  
  # wrapped in sensible-cinema-base
  class JFileChooser
    # also set_current_directory et al...
    
    # raises on failure...
    def go
      success = show_open_dialog nil
      unless success == Java::javax::swing::JFileChooser::APPROVE_OPTION
        java.lang.System.exit 1 # kills background proc...but we shouldn't let them do stuff while a background proc is running, anyway
      end
      get_selected_file.get_absolute_path
    end
    
    # match FileDialog methods...
    def set_title x
      set_dialog_title x
    end
    
    def set_file f
      set_selected_file JFile.new(f)
    end
    
    alias setFile set_file

    # choose a file that may or may not exist yet...
    def self.new_nonexisting_filechooser_and_go title = nil, default_dir = nil, default_file = nil
      out = JFileChooser.new
      out.set_title title
      if default_dir
        out.set_current_directory JFile.new(default_dir)
      end
      if default_file
        out.set_file default_file
      end
      out.go
    end
	
	def self.new_existing_dir_chooser_and_go title=nil, default_dir = nil
       chooser = JFileChooser.new;
       chooser.setCurrentDirectory(JFile.new default_dir) if default_dir
       chooser.set_title title
       chooser.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
       chooser.setAcceptAllFileFilterUsed(false)

      if (chooser.showOpenDialog(nil) == JFileChooser::APPROVE_OPTION)
        return chooser.getSelectedFile().get_absolute_path
      else
        raise "No Selection "
      end
	end
  end
  
  # awt...the native looking one...
  class FileDialog
    def go
      show
      if get_file 
        # they picked something...
        File.expand_path(get_directory + '/' + get_file)
      else
        nil
      end
    end
    
    # this actually allows for non existing files [oopsy] LODO
    def self.new_previously_existing_file_selector_and_go title, use_this_dir = nil
      out = FileDialog.new(nil, title, FileDialog::LOAD) # LODO no self in here... ?
      out.set_title title
      if use_this_dir
        # FileDialog only accepts paths a certain way...
        dir = File.expand_path(use_this_dir)
        dir = dir.gsub(File::Separator, File::ALT_SEPARATOR) if File::ALT_SEPARATOR
        out.setDirectory(dir) 
      end
      got = out.go
      raise 'cancelled choosing existing file' unless got # I think we always want to raise...
      raise 'must exist' unless File.exist? got
      got
    end
    
  end
  
  class NonBlockingDialog < JDialog
    def initialize title_and_display_text, close_button_text = 'Close'
      super nil
      lines = title_and_display_text.split("\n")
      set_title lines[0]
      get_content_pane.set_layout nil
      lines.each_with_index{|line, idx|
        jlabel = JLabel.new line
        jlabel.set_bounds(10, 15*idx, 550, 24)
        get_content_pane.add jlabel
      }
      close = JButton.new( close_button_text ).on_clicked {
        self.dispose
      }
      close.set_bounds(125,30+15*lines.length,70,25)
      get_content_pane.add close
      set_size 550, 100+15*lines.length # XXX variable width? or use swing build in better?
      set_visible true
      setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
      setLocationRelativeTo nil # center it on the screen
    end
    alias close dispose # yipes
  end
  
  def self.get_user_input(message, default = '', cancel_ok = false)
    received = javax.swing.JOptionPane.showInputDialog(message, default)
    unless cancel_ok
      raise 'user cancelled' unless received
    end
    received
  end

  def self.show_in_explorer filename_or_path
    raise 'nonexist cannot reveal in explorer?' + filename_or_path unless File.exist?(filename_or_path)
    if OS.doze?
      begin
        c = "explorer /e,/select,\"#{filename_or_path.to_filename}\"" 
        system c # command returns immediately...so system is ok
      rescue => why_does_this_happen_ignore_this_exception_it_probably_actually_succeeded
      end
    elsif OS.mac?
      c = "open -R " + "\"" + File.expand_path(filename_or_path) + "\""
      puts c
      system c
    else
      raise 'os unsupported?'
    end
  end
  
  def self.show_blocking_message_dialog message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE
    puts "please use GUI window popup... #{message[0..20]} ..."
    JOptionPane.showMessageDialog(nil, message, title, style) # I think nil is ok here, it still blocks
    # the above has no return value <sigh>
    puts 'Done with popup'
    true
  end
  
  def self.show_non_blocking_message_dialog message, close_button_text = 'Close'
    NonBlockingDialog.new(message, close_button_text) # we don't care if they close this one via the x
  end

  class DropDownSelector < JDialog # JDialog is blocking...
    
    def initialize parent, options_array, prompt_for_top_entry
      super parent, true
      @drop_down_elements = options_array
      @selected_idx = nil
      box = JComboBox.new
      box.add_action_listener do |e|
        idx = box.get_selected_index
        if idx != 0
          # don't count choosing the first as a real entry
          @selected_idx = box.get_selected_index - 1
          dispose
        end
      end

      box.add_item @prompt = prompt_for_top_entry # put something in index 0
      options_array.each{|drive|
        box.add_item drive
      }
      add box
      pack # how do you get this arbitrary size? what the...
      
    end
    
    # returns index from initial array that they selected, or raises if they hit the x on it
    def go_selected_index
      puts 'select from dropdown window'
      show # blocks...
      raise 'did not select, exited early ' + @prompt unless @selected_idx
      @selected_idx
    end
    
    def go_selected_value
      puts 'select from dropdown window'
      show # blocks...
      raise 'did not select, exited early ' + @prompt unless @selected_idx
      @drop_down_elements[@selected_idx]
    end
    
  end


end

class String
 def to_filename
  if File::ALT_SEPARATOR
    File.expand_path(self).gsub('/', File::ALT_SEPARATOR)
  else
    File.expand_path(self)
  end
 end
end
