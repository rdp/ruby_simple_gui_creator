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
require 'os'
require File.dirname(__FILE__) + '/swing_helpers'

$simple_creator_show_console_prompts = true # so that you can disable console "helper prompts" if you want to...

module SimpleGuiCreator

    JFile = java.io.File # no import for this one, so we don't lose access to Ruby's File class
   
    def self.launch_file filename
	  p filename
	  if OS.windows?
	    filename = filename.gsub('/', "\\")
		Dir.chdir(File.dirname(filename)) do
		  system(cmd = %!explorer "#{File.filename(filename)}"!) # blocks
		  p cmd
		end
	  else
	    system(%!#{OS.open_file_command} "#{filename}"!)
	  end
	end
   
    def self.open_url_to_view_it_non_blocking url
      raise 'non http url?' unless url =~ /^http/i
      if OS.windows?
        system("start #{url.gsub('&', '^&')}")
      else
        system "#{OS.open_file_command} \"#{url}\""
        sleep 2 # disallow any program exiting immediately...which can make the window *not* popup in certain circumstances...LODO fix [is it windows only?]
      end
    end
  
    # choose a file that may or may not exist yet...
    def self.new_nonexisting_or_existing_filechooser_and_go title = nil, default_dir = nil, default_filename = nil # within JFileChooser class for now...
      out = JFileChooser.new
      out.set_title title
      if default_dir
        out.set_current_directory JFile.new(default_dir)
      end
      if default_filename
        out.set_file default_filename
      end
      got = out.go true
	  if !got
	    raise "did not select anything #{title} #{default_dir} #{default_filename}"
	  end
	  got
    end
	
    # choose a file that may or may not exist yet...
    def self.new_nonexisting_filechooser_and_go title = nil, default_dir = nil, default_filename = nil # within JFileChooser class for now...
      out = JFileChooser.new
      out.set_title title
      if default_dir
        out.set_current_directory JFile.new(default_dir)
      end
      if default_filename
        out.set_file default_filename
      end
	  found_non_exist = false
	  while(!found_non_exist) 
        got = out.go true
		if got
		  if(File.exist? got) 
		    SimpleGuiCreator.show_blocking_message_dialog 'this file already exists, choose a new filename ' + got		  
		  else
		   found_non_exist = true
		  end
		else
		  raise "filechooser cancelled!"
		end
	  end
	  got
    end

	def self.new_existing_dir_chooser_and_go title=nil, default_dir = nil
      chooser = JFileChooser.new;
      chooser.setCurrentDirectory(JFile.new default_dir) if default_dir
      chooser.set_title title
      chooser.setFileSelectionMode(JFileChooser::DIRECTORIES_ONLY)
      chooser.setAcceptAllFileFilterUsed(false)
      chooser.set_approve_button_text "Select This Directory"
	  while true
        if (chooser.showOpenDialog(nil) == JFileChooser::APPROVE_OPTION)
 	       got = chooser.getSelectedFile().get_absolute_path
           unless File.directory? got
	         show_blocking_message_dialog "please select a directory that already exists, or cancel" 
	       else
            return got
           end			
        else
          raise "No dir selected/dialog cancelled " + title.to_s
        end
	  end
    end

  
  # this doesn't have an "awesome" way to force existence, just loops
  def self.new_previously_existing_file_selector_and_go title, use_this_dir = nil
  
    out = FileDialog.new(nil, title, FileDialog::LOAD) # LODO self in here... ?
    out.set_title title
	out.set_filename_filter {|file, name|
        true # works os x, not doze? some jruby forum thread discussed it...I think we start in the wrong dir here...
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
    
  # prompts for user input, raises if they cancel the prompt or if they enter nothing
  # returns nil if cancelled or empty string if empty, both requiring cancel_or_blank_ok=true
  def self.get_user_input(message, default = '', cancel_or_blank_ok = false)
    p 'please enter the information in the prompt:' + message[0..50] + '...'
    received = javax.swing.JOptionPane.showInputDialog(nil, message, default)
    p 'received answer:' + received.to_s # a string, an empty string, or a nil
    if !received.present?
      if !cancel_or_blank_ok
        raise 'user cancelled input prompt ' + message unless received
  	    raise 'did not enter anything?' + message unless received.present?
      end
      #received = nil # allow empty string to pass through
    end
    received
  end
  
  class << self
    alias :get_input :get_user_input 
  end
  
  def self.to_filename string
   if File::ALT_SEPARATOR
     out = string.gsub('/', File::ALT_SEPARATOR)
   else
     out = File.expand_path(string) # TODO test this with Die drei Br�der folders, does it lose encoding?
   end
   # huh?
   # out.force_encoding(string.encoding) # jruby bug? it converts from utf-8 to IBM437 huh wuh?
   out
  end

  def self.show_in_explorer filename_or_path
    raise 'nonexistent file cannot reveal in explorer?' + filename_or_path unless File.exist?(filename_or_path)
    if OS.doze?
      begin
        raise 'jruby doesnt like quotes in filenames or used to not?' if filename_or_path =~ /"/
        exe = "#{__DIR__}/../../vendor/reveal_reuse_explorer.exe"
        c = "\"#{exe}\" \"#{to_filename filename_or_path}\""
        if !system(c)
          p "unable to reveal #{c}, falling back on #{backup_command}"        
          backup_command = "explorer /e,/select,#{to_filename filename_or_path}"
          system(backup_command) # commands return immediately...so calling system on it is ok
        end 
      rescue => why_does_this_happen_ignore_this_exception_it_probably_actually_succeeded
	    3 # for debugging so it can break here...not sure why this used to occur with the explorer /e style...
      end
    elsif OS.mac?
      c = "open -R " + "\"" + filename_or_path + "\""
      system c # returns immediately
    elsif OS.linux?
      c = "nohup nautilus --no-desktop \"#{filename_or_path}\"" 
      system c
    else
      raise 'os reveal unsupported?'
    end
  end
  
  def self.show_blocking_message_dialog message, title = message.split("\n")[0], style= JOptionPane::INFORMATION_MESSAGE
    puts "please use GUI window popup... #{message} ..." if $simple_creator_show_console_prompts
	
	invoke_in_gui_thread_non_blocking {
	  # have to invoke this in a separate thread or it returns these spurious "action items" to, for instance, checkboxes.  Yikes, java!
	  # http://betterlogic.com/roger/2014/04/jruby-woe-25
	  temp_frame = JFrame.new
	  temp_frame.minimize
	  temp_frame.show
	
      begin
	    JOptionPane.showMessageDialog(temp_frame, message, title, style)
	  ensure
	    temp_frame.dispose
	  end
      # the above has no return value <sigh> so just return true
	}
    true
  end
  
  class << self
    alias :show_message :show_blocking_message_dialog
    alias :display_text :show_blocking_message_dialog # hate having to remember these...
	alias :show_text :show_blocking_message_dialog
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
    got = JOptionPane.showConfirmDialog(nil, pwd, text, JOptionPane::OK_CANCEL_OPTION) < 0
    if got
      raise 'cancelled password prompt ' + text
    else
      # convert to ruby string [?]
      out = ''
      pwd.password.each{|b|
        out << b
      }
      out
    end
  end

  def self.run_later(seconds) # schedule something to be run by the GUI later....to avoid using spawning threads, basically, 
    #I guess, for the same purpose or maybe there's other benefits, like...it runs in the swing thread, so you may avoid some concurrency issues...keeps things saner?
    timer = javax.swing.Timer.new(seconds*1000, nil)
	timer.repeats=false # don't loop, just fire once :)
	timer.add_action_listener {
	  yield
	}
	timer.start
  end
  
  def self.hard_exit!; java::lang::System.exit 0; end

  def self.invoke_in_gui_thread_non_blocking
    SwingUtilities.invoke_later { yield }
  end
  
  def self.invoke_in_gui_thread_blocking # sometimes I think I might  need this, but it never seems to help...
    SwingUtilities.invoke_and_wait { yield } # invoke_later ?
  end

end