# encoding: UTF-8
require 'java'

require File.dirname(__FILE__) + '/swing_helpers.rb' # for JButton#on_clicked, etc.,

# for documentation, see the README file
module SimpleGuiCreator

  include_package 'javax.swing'; [JFrame, JPanel, JButton, JTextArea, JLabel, UIManager, JScrollPane, JCheckBox, JComboBox]
  java_import java.awt.Font
  
  class ParseTemplate < JFrame
    
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
    parse_setup_string File.read(filename)
    self
  end
  
  # "matches" whatever the template string looks like...
  def parse_setup_string string
    @frame = self # LODO refactor
    @current_y = 10
    @window_max_x = 100
    all_lines = string.lines.to_a
    all_lines.each_with_index{|line, idx|
      begin
      @current_x = 10
      if line =~ /\t/
        raise "sorry, tabs arent allowed, but you can request it"
      end
      button_regex = /\[(.*?)\]/      
      text_regex = /"([^"]+)"/ # "some text:name"
      blank_line_regex = /^\s*(|\|)\s+(|\|)\s*$/ # matches " | | " or just empty...
      title_regex = /\s*[-]+([\w ]+)[-]+\s*$/  # ----(a Title)---
      @current_line_height = 25      
      if line =~ title_regex
        @frame.set_title $1 # done :)
        @frame.original_title = $1.dup.freeze # freeze...LOL        
      elsif line =~ blank_line_regex
        @current_y += @current_line_height
      else
        # attempt an line of several elements...
        cur_x = 0        
        while next_match = closest_next_regex_match([button_regex, text_regex], line[cur_x..-1])
          cur_spot = line[cur_x..-1] =~ next_match
          cur_spot += cur_x # we had only acted on a partial line, above, so add in the part we didn't do, to get the right offset number
          captured = $1
          end_spot = cur_spot + captured.length
          if next_match == button_regex
            handle_button_at_current captured, cur_spot, end_spot, all_lines, idx
          elsif next_match == text_regex
            label = JLabel.new
            setup_element(label, captured)            
          end
          cur_x = end_spot
        end        
        @current_y += @current_line_height
      end
      
      # this causes it to build in 'realtime' by resizing the window as it gets lower and lower...
      @frame.set_size @window_max_x + 25, @current_y + 15 # lodo do we need 15 here? I don't see why...
      rescue
        puts "Parsing failed on line #{line.inspect} number: #{idx+1}!"
        raise
      end
    }
    self
  end
  
  private
  
  def closest_next_regex_match options, line
    mapped = options.map{|option| line =~ option}
    best = 10000
    mapped.each{|number| best = [best, number].min if number}
    if best == 10000
      return nil
    else
      return options[mapped.index(best)] # yikes that was hard
    end
  end
  
  def handle_button_at_current captured, cur_spot, end_spot, all_lines, idx
    count_lines_below = 0
    matching_blank_text_area_string = '[' + ' '*(end_spot-cur_spot) + ']'
    empty_it_out = matching_blank_text_area_string.gsub(/[\[]/, '_') # can't actually remove it...
    for line2 in all_lines[idx+1..-1]
      if line2[cur_spot..(end_spot+1)] == matching_blank_text_area_string
        line2[cur_spot, end_spot-cur_spot+2] = empty_it_out # :)
        count_lines_below += 1
      else
        break
      end
    end
    text, code_name_with_attrs = split_int_text_name_and_code captured
    text.strip! # hope we don't care for buttons...for now...
    if count_lines_below > 0
      rows = count_lines_below + 1 # at least 2...
      text_area = JTextArea.new(rows, captured.split(':')[0].length)
      text_area.text="\n"*rows
      # width?
      scrollPane = JScrollPane.new(text_area)
      setup_element(scrollPane, captured, scrollPane.getPreferredSize.height, text_area)
    elsif text == "✓"
      check_box = JCheckBox.new
      setup_element(check_box, ':' + code_name_with_attrs, nil, check_box, check_box.getPreferredSize.width)
    elsif text.end_with?("\\/") || text.end_with?("▼") # dropdowns
      drop_down = JComboBox.new
      if text.end_with?("▼")      
        initial_value = text = text.gsub(/▼$/, '')
      else
        initial_value = text[0..-3].strip
      end
      if initial_value.present?
        drop_down.add_item initial_value.strip # set the top line as default
      end
      setup_element drop_down, ':' + code_name_with_attrs, nil, drop_down, drop_down.getPreferredSize.width
    else
      # a "normal" button
      button = JButton.new
      setup_element(button, captured)
    end
  end
  
  def get_text_width text
    get_text_dimentia(text).width
  end
  
  def get_text_dimentia text
    font = UIManager.getFont("Label.font")
    frc = java.awt.font.FontRenderContext.new(font.transform, true, true)
    textLayout = java.awt.font.TextLayout.new(text, font, frc)
    textLayout.bounds # has #height and #width
  end
  
  def split_int_text_name_and_code name_and_code
      if name_and_code.include?(':') && !name_and_code.end_with?(':') # like "Start:start_button"  or "start:button:code_name,attribs" but not "Hello:" let that through
        text = name_and_code.split(':')[0..-2].join(':') # only accept last colon, so they can have text with colons in it
        code_name_with_attrs = name_and_code.split(':')[-1]
        [text, code_name_with_attrs]
      else
        [name_and_code, nil]
      end
  end
  
  def setup_element element, name_and_code, height=nil, set_text_on_this = element, width=nil
          abs_x = nil
          abs_y = nil
          text, code_name_with_attrs = split_int_text_name_and_code name_and_code
          if code_name_with_attrs
            # extract attributes
            if code_name_with_attrs.split(',')[0] !~ /=/
              # then like code_name,width=250,x=y
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
            if type = attributes_hashed.delete('font')
              if type == "fixed_width"
                set_text_on_this.font = Font.new("Monospaced", Font::PLAIN, 14)
              else
                 raise "all we support is fixed_width font as of yet #{type} #{name_and_code}"
              end                
            end
            
            for name2 in ['abs_x', 'abs_y', 'width', 'height']
              var = attributes_hashed.delete(name2)
              if var
                if var =~ /chars$/
                  count = var[0..-5].to_i
                  var = get_text_width('m'*count) # TODO fails for height 30chars
                elsif var =~ /px$/
                  var = var[0..-3].to_i
                else
                  var = var.to_i # allow it to be clean :P
                end
                raise "#{var} has value of zero?" if var == 0
                eval("#{name2} = #{var}") # ugh
              end
            end
            raise "unknown attributes found: #{attributes_hashed.keys.inspect} #{attributes_hashed.inspect} #{code_name} #{name_and_code}" if attributes_hashed.length > 0
          end
          if !width
            if text.blank?
              raise 'cannot have blank original text without width specifier:' + name
            end
            if text.strip != text
              # let blank space count as "space" for now, but don't actually set it LOL
              # is this good for variable spaced fonts, though?
              width = get_text_width("|" + text + "|") + 35
              text.strip!
            else
              width = get_text_width(text) + 35
            end
           end
          set_text_on_this.text=text if text.present?
          abs_x ||= @current_x
          abs_y ||= @current_y
          height ||= 20
          element.set_bounds(abs_x, abs_y, width, height)
          @frame.panel.add element
          if code_name
            code_name.strip!
            raise "double name not allowed #{name} #{code_name}" if @frame.elements[code_name.to_sym]
            @frame.elements[code_name.to_sym] = set_text_on_this # just symbol access for now...
          end
          @current_x = [@current_x, abs_x + width + 5].max
          @current_line_height = [@current_line_height, (abs_y + height + 5)-@current_y].max # LODO + 5 magic number? 25 - 20 hard coded? hmm...
          
          @window_max_x = [@window_max_x, @current_x].max # have to track x, but not y
  end
  
  end

  private  
  def _dgb
          require 'rubygems'
          require 'ruby-debug'
          debugger
  end

end