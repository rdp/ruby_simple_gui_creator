require 'java'

require File.dirname(__FILE__) + '/swing_helpers.rb' # for #close, etc., basically required as of today..

# for docs, see the README
module ParseTemplate
  def _dgb
		  require 'rubygems'
		  require 'ruby-debug'
		  debugger
  end

  include_package 'javax.swing'; [JFrame, JPanel, JButton, JTextArea, JLabel, UIManager]
  
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
  
  # "matches" whatever the template string looks like...
  def parse_setup_string string
    @frame = self # LODO refactor
	@current_y = 10
	@window_max_x = 100
	all_lines = string.lines.to_a
    all_lines.each_with_index{|line, idx|
	  @current_x = 10
	  if line =~ /\t/
	    raise "sorry, tabs arent allowed, but you can request it #{line.inspect} line #{idx}"
	  end
	  button_line_regex = /\[(.*?)\]/
	  #>> "|  [Setup Preferences:preferences] [Start:start] [Stop:stop] |" .scan button_line_regex
	  #=> [["Setup Preferences:preferences"], ["Start:start"], ["Stop:stop"]]
	  
	  text_regex = /"([^"]+)"/ # "some text:name"
	  title_regex = /\s*[-]+([\w ]+)[-]+\s*$/  # ----(a Title)---
	  @current_line_height = 25
	  if line =~ title_regex
	    @frame.set_title $1 # done :)
		@frame.original_title = $1.dup.freeze # freeze...LOL		
	  elsif line =~ button_line_regex	   
	    # button, or TextArea, which takes an x, y        
		cur_x = 0		
		while cur_spot = (line[cur_x..-1] =~ button_line_regex)
		  cur_spot += cur_x# we had only acted on a partial line, above, so add in the part we didn't do
		  name = $1
		  end_spot = cur_spot + name.length
		  count_lines_below = 0
		  matching_blank_text_area_string = '[' + ' '*(end_spot-cur_spot) + ']'
		  empty_it_out = matching_blank_text_area_string.gsub(/./, ' ')
		  for line2 in all_lines[idx+1..-1]
		    if line2[cur_spot..(end_spot+1)] == matching_blank_text_area_string
			  line2[cur_spot, end_spot-cur_spot+2] = empty_it_out # :)
			  count_lines_below += 1
			else
			  break
			end
		  end
		  if count_lines_below > 0
		    height =  count_lines_below + 1
		    text_area = JTextArea.new(name.split(':')[0].length, height)
			text_area.text="\n"*height
			# width?
			setup_element(text_area, name, text_area.getPreferredSize.height)
		  else
			button = JButton.new
			setup_element(button, name)
		  end		  
		  cur_x = end_spot # creep forward within this line...
		end		
 		@current_y += @current_line_height
	  elsif line =~ text_regex
	    for name in line.scan(text_regex)
	      label = JLabel.new
		  setup_element(label, name[0])
        end
	    @current_y += @current_line_height
	  end
	}
	@frame.set_size @window_max_x + 25, @current_y + 40
    self
  end
  
  private
  
  def get_text_width text
    get_text_dimentia(text).width
  end
  
  def get_text_dimentia text
	font = UIManager.getFont("Label.font")
    frc = java.awt.font.FontRenderContext.new(font.transform, true, true)
    textLayout = java.awt.font.TextLayout.new(text, font, frc)
    textLayout.bounds # has #height and #width
  end
  
  def setup_element element, name, height=nil
		  abs_x = nil
		  abs_y = nil
		  #height = nil
		  width = nil
		  if name.include? ':' # like "Start:start_button" ... disallows using colon at all, but hey...
		    text = name.split(':')[0..-2].join(':') # only accept last colon, so they can have text with colons in it
			code_name_with_attrs = name.split(':')[-1]
			if code_name_with_attrs.split(',')[0] !~ /=/
			  # like code_name,width=250,x=y
			  code_name, *attributes = code_name_with_attrs.split(',')
			else
			  code_name = nil
			  attributes = code_name_with_attrs.split(',')
			end
			  attributes_hashed = {}
			  attributes.each{|attr| 
			    key, value = attr.split('=')
			    attributes_hashed[key.strip] = value.strip
			  }
			  for name in ['abs_x', 'abs_y', 'width', 'height']
			    var = attributes_hashed.delete(name)
				if var
				  var = var.to_i
				  raise "#{var} has value of zero?" if var == 0
				  eval("#{name} = #{var}") # ugh
				end
			  end
			  raise "unknown attributes found: #{attributes_hashed.keys.inspect} #{attributes_hashed.inspect} #{code_name}" if attributes_hashed.length > 0
		  else
		    # no code name
		    text = name
		  end
		  if !width
		    if text.blank?
			  raise 'cannot have blank original text without some size specifier' + name
			end
			if text.strip != text
			  # let blank space count as "space" for now, but don't actually set it LOL
			  width = get_text_width("|" + text + "|") + 35
			  text.strip!
			else
              width = get_text_width(text) + 35
			end
 		  end
		  element.text=text
		  abs_x ||= @current_x
		  abs_y ||= @current_y
		  height ||= 20
		  element.set_bounds(abs_x, abs_y, width, height)
          @frame.panel.add element
		  if code_name
		    code_name.rstrip!
		    raise "double name not allowed #{name} #{code_name}" if @frame.elements[code_name.to_sym]
            @frame.elements[code_name.to_sym] = element # just symbol access for now...
		  end
		  @current_x = [@current_x, abs_x + width + 5].max
		  @current_line_height = [@current_line_height, (abs_y + height + 5)-@current_y].max # LODO + 5 magic number? 25 - 20 hard coded? hmm...
		  
	      @window_max_x = [@window_max_x, @current_x].max # have to track x, but not y
  end
  
  end

end