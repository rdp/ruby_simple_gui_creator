require 'simple-ruby-gui-creator.rb'

a = ParseTemplate::JFramer.new
a.parse_setup_string <<EOL

| [a button:button_name,width=100,height=100,x=50,y=50] |
| [another button:button_name2] |
| [a button:button_name3,width=100,height=100,x=50,y=50] |

EOL