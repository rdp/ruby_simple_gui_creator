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
require 'rubygems'
require 'ffi'
require 'java'
require 'os'

module MouseControl # base
  MouseInfo = java.awt.MouseInfo
  
  class << self
    @keep_going = true
    def shutdown
      @keep_going = false
    end
    
    def jitter_forever_in_own_thread
  
      old_x, old_y = get_mouse_location
      Thread.new {
        @keep_going = true
        while(@keep_going)
          move_y = 8 # just enough for VLC when full screened...
          cur_x, cur_y = get_mouse_location
          if(cur_x == old_x && cur_y == old_y)
            @total_movements += 1
            # blit it up
            move_mouse_relative(0, move_y)
            move_mouse_relative(0, move_y * -1)
            # let it move it back
            sleep 0.05
            old_x, old_y = get_mouse_location
            sleep 0.75
          else
            # user has been moving the mouse around, so we don't need to, to not annoy them
            old_x, old_y = get_mouse_location
            sleep 3
          end
        end
        puts 'mouse control, shutting down thread'
      }
    end
    
    def single_click_left_mouse_button
      left_mouse_down!
      left_mouse_up!
      p "CLICKED LEFT MOUSE BUTTON"
    end
    
    # [x, y]
    def get_mouse_location
      loc = MouseInfo.getPointerInfo.getLocation # pure java!
      [loc.x, loc.y]
    end
    
    attr_accessor :total_movements
    
  end
    
end

MouseControl.total_movements=0 # ruby is a bit freaky with these...

if OS.windows?
  require_relative 'mouse_control_windows'
elsif OS.mac?
  require_relative 'mouse_control_mac'
else
  raise 'unsupported os for mouse yet'
end
