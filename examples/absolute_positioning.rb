require 'rubygems'
require 'sane'
require __DIR__ +  '/../lib/simple-ruby-gui-creator.rb'

a = ParseTemplate::JFramer.new
a.parse_setup_string <<EOL

| [a button:button_name,width=100,height=100,abs_x=50,abs_y=50] [a third button]
| [another button:button_name2] [another button:button_name4]|
| [another button:button_name3] |

EOL