require 'java'
require File.dirname(__FILE__) + '/swing_helpers.rb'

def _dgb
		  require 'rubygems'
		  require 'ruby-debug'
		  debugger

		  end

module ParseTemplate

  include_package 'javax.swing'; [JFrame, JPanel, JButton, JLabel]
  
  class JFramer < JFrame
    
    def initialize 
      super()
      @panel = JPanel.new
      @elements = {}
      @panel.set_layout nil
      add @panel # why can't I just slap these down? panel? huh?
	  #show
	end 
	attr_reader :elements
	attr_reader :panel
	attr_accessor :original_title
  end
  
  def self.parse_file filename
    parse_string File.read(filename)
  end
  
  def self.get_text_width text
	font = UIManager.getFont("Label.font")
    frc = java.awt.font.FontRenderContext.new(font.transform, true, true)
    textLayout = java.awt.font.TextLayout.new(text, font, frc)
    textLayout.bounds.width
  end
  
  def self.setup_element element, name, width=nil
  		  # name is now like ["Setup Preferences:preferences"]
		  name = name[0]
		  if name.include? ':' # like "Start:start_button" ... disallows using colon at all, but hey...
		    text = name.split(':')[0..-2].join(':') # only accept last colon, so they can have text with colons in it
			name = name.split(':')[-1]
			if name.include? ','
			  width = name.split(',')[1].to_i
			  raise if width == 0
			  name = name.split(',')[0]
			end
		  else
		    text = name
		  end
		  element.text=text
		  if !width
		    if text.blank?
			  raise 'cannot have blank original text without some size specifier' + name
			end
            width = get_text_width(text) + 35
 		  end
		  element.set_bounds(@current_x, @current_y, width, 20)
		  @current_x += width + 5 # doesn't have a 'real' size yet...I guess...yikes
          @frame.panel.add element
          @frame.elements[name] = element
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
		@frame.original_title = $1.dup.freeze # freeze...LOL		
	  elsif l =~ button_line_regex
        l.scan(button_line_regex).each{|name|
		  button = JButton.new
		  setup_element(button, name)
		}
 		@current_y += 25
	  elsif l =~ text_regex
	    for name in l.scan(text_regex)
	      label = JLabel.new
		  setup_element(label, name)
        end
	    @current_y += 25
	  end
	}
	@frame.set_size @max_x+25, @current_y+40
	@frame
  end

end