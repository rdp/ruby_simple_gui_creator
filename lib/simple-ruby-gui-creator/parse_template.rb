require 'java'

require File.dirname(__FILE__) + '/swing_helpers.rb' # for #close, etc., basically required as of today..

# for docs, see the README
module ParseTemplate
  def _dgb
		  require 'rubygems'
		  require 'ruby-debug'
		  debugger
  end

  include_package 'javax.swing'; [JFrame, JPanel, JButton, JLabel, UIManager]
  
  class JFramer < JFrame
    
    def initialize 
      super()
      @panel = JPanel.new
      @elements = {}
      @panel.set_layout nil
      add @panel # why can't I just slap these down? panel? huh?
 	  show # this always bites me...I new it up an it just doesn't appear...
	end
	
	attr_reader :panel
	attr_reader :elements
	attr_accessor :original_title
	attr_accessor :frame
	
  def parse_setup_filename filename
    parse_string File.read(filename)
	self
  end
  
  # "matches" whatever the template says
  def parse_setup_string string
  
    @frame = self # LODO refactor
	@current_y = 10
	@max_x = 100
    string.each_line{|l|
	  @current_x = 10
	  button_line_regex = /\[(.*?)\]/
	  #>> "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |" .scan button_line_regex
	  #=> [["Setup Preferences:preferences"], ["Start:start"], ["Stop:stop"]]
	  
	  text_regex = /"([^"]+)"/ # "some text:name"
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
    self
  end
  
  private
  def get_text_width text
	font = UIManager.getFont("Label.font")
    frc = java.awt.font.FontRenderContext.new(font.transform, true, true)
    textLayout = java.awt.font.TextLayout.new(text, font, frc)
    textLayout.bounds.width
  end
  
  def setup_element element, name, width=nil
  		  # name is now like ["Setup Preferences:preferences"]
		  name = name[0]
		  if name.include? ':' # like "Start:start_button" ... disallows using colon at all, but hey...
		    text = name.split(':')[0..-2].join(':') # only accept last colon, so they can have text with colons in it
			code_name = name.split(':')[-1]
			# might be code_name,width=250,x=y
			if code_name.include? ','
			  code_name, attributes = code_name.split(',')
			  attributes_hashed = {}
			  attributes.split(',').each{|attr| 
			    key, value = attr.split('=')
			    attributes_hashed[key] = value
			  }
			  width = attributes_hashed.delete('width').to_i
			  raise "#{name} has no width, or zero width?" if width == 0
			  raise "unknown attributes #{attributes_hashed} #{name}" if attributes_hashed.length > 0
			end
		  else
		    # no code name
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
		  if code_name
		    code_name.rstrip!
		    raise "double name not allowed #{name} #{code_name}" if @frame.elements[code_name.to_sym]
            @frame.elements[code_name.to_sym] = element # just symbol access for now...
		  end
	      @max_x = [@max_x, @current_x].max
  end
  
  end

end