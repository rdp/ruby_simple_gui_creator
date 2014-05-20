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

module MouseControl # extend it in line :)
  $: << File.dirname(__FILE__) + "/rumouse-0.0.6/lib/"
  require 'rumouse' # vendorized gem
  class << self
    @@mouse = RuMouse.new # can't use @mouse? huh wuh?

    def move_mouse_relative dx, dy 
      old_pos = @@mouse.position
      old_x = old_pos[:x]
      old_y = old_pos[:y]
      @@mouse.move old_x + dx, old_y + dy      
    end

    @@state = :up

    def left_mouse_down!
      old_pos = @@mouse.position
      @@mouse.release old_pos[:x], old_pos[:y] # force it up first, just in case [?]
      @@mouse.press old_pos[:x], old_pos[:y]
      @@state = :down
    end
    
    def left_mouse_up!
      old_pos = @@mouse.position
      @@mouse.release old_pos[:x], old_pos[:y]
      @@state = :up
    end

    def left_mouse_button_state
      @@state # TODO not fake this!
    end
  end

end
