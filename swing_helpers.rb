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
require 'sane' # gem dependency

module SwingHelpers 
  
 include_package 'javax.swing'
 # will use  these constants (http://jira.codehaus.org/browse/JRUBY-5107)
 [JProgressBar, JButton, JFrame, JLabel, JPanel, JOptionPane,
   JFileChooser, JComboBox, JDialog, SwingUtilities, JSlider, JPasswordField] 
 include_package 'java.awt'
 [FlowLayout, Font, BorderFactory, BorderLayout]
 java_import java.awt.event.ActionListener
 JFile = java.io.File
 java_import java.awt.FileDialog
 java_import java.lang.System
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
      returned = JOptionPane.showConfirmDialog SwingHelpers.get_always_on_top_frame, message, title, JOptionPane::YES_NO_CANCEL_OPTION
      SwingHelpers.close_always_on_top_frame
      old.each{|name, old_setting| UIManager.put(name, old_setting)}
      out = JOptionReturnValuesTranslator[returned]
      if !out || !names_hash.key?(out)
        raise 'canceled or exited an option prompt:' + out.to_s + ' ' + message
      end
      out
    end
    
 end

 class JButton
   def initialize(*args)
    super(*args)
    set_font Font.new("Tahoma", Font::PLAIN, 11)
   end
  
   def on_clicked &block
     raise unless block # sanity check
     @block = block
     add_action_listener do |e|
       begin
         block.call
       rescue Exception => e
             # e.backtrace[0] == "/Users/rogerdpack/sensible-cinema/lib/gui/create.rb:149:in `setup_create_buttons'"
             bt_out = ""
             for line in e.backtrace[0..1]
               backtrace_pieces = line.split(':')
               backtrace_pieces.shift if OS.doze? # ignore drive letter
	       filename = backtrace_pieces[0].split('/')[-1]
	       line_number =  backtrace_pieces[1]
               bt_out += " #{filename}:#{line_number}" 
             end
         puts 'button cancelled somehow!' + e.to_s + ' ' + get_text[0..50] + bt_out
         if $VERBOSE
          puts "got fatal exception thrown in button [aborted] #{e} #{e.class} #{e.backtrace[0]}"
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
  
   def enable
    set_enabled true
   end
  
   def disable
    set_enabled false
   end
  
 end

 ToolTipManager.sharedInstance().setDismissDelay(10000)

 class JFrame
  
   class CloseListener < java.awt.event.WindowAdapter
     def initialize parent, &block
	   super()
	   @parent = parent
	   @block = block
	 end
	 
     def windowClosed event # sometimes this, sometimes the other...
	   if @block
	    b = @block # force avoid calling it twice, since swing does seem to call this method twice, bizarrely
		@block = nil
		b.call
	   end
	 end
	 
	 def windowClosing event
	    #p 'windowClosing' # hitting the X goes *only* here, and twice? ok this is messed up
		@parent.dispose
	 end
   end
   
   def initialize *args
     super *args # we do get here...
	 # because we do this, you should *not* have to call the unsafe:
	 # setDefaultCloseOperation(EXIT_ON_CLOSE)
	 # which basically does a System.exit(0) when the last jframe closes. Yikes jdk, yikes.	 
	 addWindowListener(CloseListener.new(self))
   end   
   
   def close
     dispose # <sigh>
   end
   
   def dispose_on_close
     # the default
   end
   
   def after_closed &block
	 addWindowListener(CloseListener.new(self) {
	   block.call 
	 })
   end
  
   def on_minimized &block
    addWindowStateListener {|e|
	  if getState ==  java.awt.Frame::ICONIFIED
        block.call	  
	  elsif e == java.awt.event.WindowEvent::WINDOW_ICONIFIED 
	    # we never get here...
        p 'on minimized2'
        block.call 
      end
    }
   end
  
   def bring_to_front # kludgey...but said to work for swing frames...
    java.awt.EventQueue.invokeLater{
      unminimize
      toFront
      repaint
    }      
   end
   
   def minimize
     setState(java.awt.Frame::ICONIFIED)
   end
  
   def unminimize
     setState(java.awt.Frame::NORMAL) # this line is probably enough, but do more just in case
     setVisible(true)
   end
  
   alias restore unminimize
  
   # avoid jdk6 always on top bug http://betterlogic.com/roger/2012/04/jframe-setalwaysontop-doesnt-work-after-using-joptionpane/
   alias always_on_top_original always_on_top=
  
   def always_on_top=bool 
    always_on_top_original false
    always_on_top_original bool
   end

   def set_always_on_top bool
      always_on_top=bool
   end
  
   def setAlwaysOnTop bool
      always_on_top=bool
   end
  
  end # class JFrame
  
  def self.open_url_to_view_it_non_blocking url
      raise 'non http url?' unless url =~ /^http/i
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
    def self.new_nonexisting_filechooser_and_go title = nil, default_dir = nil, default_file = nil # within JFileChooser class for now...
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
	
  end

  def self.new_existing_dir_chooser_and_go title=nil, default_dir = nil
    chooser = JFileChooser.new;
    chooser.setCurrentDirectory(JFile.new default_dir) if default_dir
    chooser.set_title title
    chooser.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
    chooser.setAcceptAllFileFilterUsed(false)
    chooser.set_approve_button_text "Select Directory"

    if (chooser.showOpenDialog(nil) == JFileChooser::APPROVE_OPTION)
     return chooser.getSelectedFile().get_absolute_path
    else
     raise "No dir selected " + title.to_s
    end
  end

  # awt...the native looking one...
  class FileDialog
    def go
      show
	  dispose # allow app to exit :P
      if get_file 
        # they picked something...
        File.expand_path(get_directory + '/' + get_file)
      else
        nil
      end
    end
  end
  
  # this doesn't have an "awesome" way to force existence, just loops
  def self.new_previously_existing_file_selector_and_go title, use_this_dir = nil
  
    out = FileDialog.new(nil, title, FileDialog::LOAD) # LODO no self in here... ?
    out.set_title title
	out.set_filename_filter {|file, name|
	  puts 'hello'
	  puts file, name
	}
	
    if use_this_dir
      # FileDialog only accepts paths a certain way...
      dir = File.expand_path(use_this_dir)
      dir = dir.gsub(File::Separator, File::ALT_SEPARATOR) if File::ALT_SEPARATOR
      out.setDirectory(dir) 
    end
	got = nil
    while(!got)
	  got = out.go
      raise 'cancelled choosing existing file ' + title unless got # I think we always want to raise...
	  unless File.exist? got
	    show_blocking_message_dialog "please select a file that already exists, or cancel" 
		got = nil
	  end
	end
    got
  end
    
  class NonBlockingDialog < JDialog
    def initialize title_and_display_text, close_button_text = 'Close'
      super nil # so that set_title will work
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
      number_of_lines = lines.length
      close.set_bounds(125,30+15*number_of_lines, close_button_text.length * 15,25)
      get_content_pane.add close
      set_size 550, 100+(15*number_of_lines) # XXX variable width? or use swing build in better?
      set_visible true
      setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
      setLocationRelativeTo nil # center it on the screen
      
    end
    alias close dispose # yikes
  end
  
  def self.get_always_on_top_frame
    fake_frame = JFrame.new
    fake_frame.setUndecorated true # so we can have a teeny [invisible] window
    fake_frame.set_size 1,1
    fake_frame.set_location 300,300 # so that option pane's won't appear upper left
    #fake_frame.always_on_top = true
    fake_frame.show
    @fake_frame = fake_frame
  end
  
  def self.close_always_on_top_frame
    @fake_frame.close
  end
  
  # prompts for user input, raises if they cancel the prompt or if they enter nothing
  def self.get_user_input(message, default = '', cancel_or_blank_ok = false)
    p 'please enter the information in the prompt:' + message[0..50] + '...'
    received = javax.swing.JOptionPane.showInputDialog(get_always_on_top_frame, message, default)
    close_always_on_top_frame
    if !cancel_or_blank_ok
      raise 'user cancelled input prompt ' + message unless received
  	  raise 'did not enter anything?' + message unless received.present?
    end
    p 'received answer:' + received
    received
  end

  def self.show_in_explorer filename_or_path
    raise 'nonexistent file cannot reveal in explorer?' + filename_or_path unless File.exist?(filename_or_path)
    if OS.doze?
      begin
        c = "explorer /e,/select,#{filename_or_path.to_filename}" 
        system c # command returns immediately...so system is ok
      rescue => why_does_this_happen_ignore_this_exception_it_probably_actually_succeeded
      end
    elsif OS.mac?
      c = "open -R " + "\"" + filename_or_path.to_filename + "\""
      puts c
      system c
    else
      raise 'os reveal unsupported?'
    end
  end
  
  def self.show_blocking_message_dialog message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE
    puts "please use GUI window popup... #{message} ..."
    JOptionPane.showMessageDialog(get_always_on_top_frame, message, title, style)
    # the above has no return value <sigh> so just return true
    close_always_on_top_frame
    true
  end
  
  class << self
    alias :show_message :show_blocking_message_dialog
  end
  
  def self.show_non_blocking_message_dialog message, close_button_text = 'Close'
    NonBlockingDialog.new(message, close_button_text) # we don't care if they close this one via the x
  end

  def self.show_select_buttons_prompt message, names_hash = {}
    JOptionPane.show_select_buttons_prompt message, names_hash
  end
  
  def self.get_password_input text
    p 'please enter password at prompt'
    pwd = JPasswordField.new(10)
    got = JOptionPane.showConfirmDialog(get_always_on_top_frame, pwd, text, JOptionPane::OK_CANCEL_OPTION) < 0
    close_always_on_top_frame
    if got
      raise 'cancelled ' + text
    else
      # convert to ruby string [?]
      out = ''
      pwd.password.each{|b|
        out << b
      }
      out
    end
  end

  class DropDownSelector < JDialog # JDialog is blocking...
    
    def initialize parent, options_array, prompt_for_top_entry
      super parent, true
      set_title prompt_for_top_entry
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

  def self.hard_exit!; java::lang::System.exit 0; end
  
  def self.invoke_in_gui_thread # sometimes I think I need this, but it never seems to help
    SwingUtilities.invoke_later { yield }
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
