require 'java'
require 'swing_helpers'

module ParseTemplate

  include_package 'javax.swing'; [JFrame, JPanel, JButton, JLabel]
  
  class JFramer < JFrame
    
    def initialize 
      super()
      @panel = JPanel.new
      @buttons = {}
      @panel.set_layout nil
      add @panel # why can't I just slap these down? panel? huh?
	  #show
	end 
	attr_accessor :buttons
	attr_accessor :panel
  end
  
  def self.parse_filename filename
    parse_string File.read(filename)
  end
  
  def self.setup_element element, name
  		  # name is now like ["Setup Preferences:preferences"]
		  name = name[0]
		  if name.include? ':' # like "Start:start_button" ... disallows using colon at all, but hey...
		    text = name.split(':')[0]
			name = name.split(':')[1]
		  else
		    text = name
		  end
		  element.text=text
          #button.set_location(current_x, current_y)
		  element.set_bounds(@current_x, @current_y, 100, 20)
		  @current_x += 100 + 5 # doesn't have a 'real' size yet...I guess...yikes
          @frame.panel.add element
          @frame.buttons[name] = element
	      @max_x = [@max_x, @current_x].max
  end
  
  # returns a jframe that "matches" whatever the template says
  def self.parse_string string
    got = string
    # >>"[ a ] [ b ]".split(/(\[.*?\])/)
    # => ["", "[ a ]", " ", "[ b ]"]	
    @frame = JFramer.new
	@current_y = 10
	@max_x = 100
    got.each_line{|l|
	  @current_x = 10
	  button_line_regex = /\[(.*?)\]/
	  # >> "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |" .scan  /\[(.*?)\]/
	  # => [["Setup Preferences:preferences"], ["Start:start"], ["Stop:stop"]]
	  
	  text_regex = /<<(.*?)>>/ # 
	  
	  title_regex = /\s*[-]+([\w ]+)[-]+\s*$/  # ----(a Title)---
	  if l =~ title_regex
	    @frame.set_title $1 # done :)
	  elsif l =~ button_line_regex
        got.scan(button_line_regex).each{|name|
		  button = JButton.new
		  setup_element(button, name)
		}
 		@current_y += 25
	  elsif l =~ text_regex
	    for name in got.scan(text_regex)
	      label = JLabel.new
		  setup_element(label, name)
        end
	    @current_y += 25
	  end
	}
	@frame.set_size @max_x+25, @current_y+45
	@frame
  end

end