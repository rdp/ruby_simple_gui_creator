# just autoload everything always :)

module SimpleGuiBootStrap
  def self.snake_case string
    string = string.to_s.dup
    string.gsub!(/::/, '/')
    string.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
    string.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    string.tr!("-", "_")
    string.downcase!
	string
  end
end

for clazz in [:DriveInfo, :MouseControl, :ParseTemplate, :PlayAudio, :PlayMp3Audio, :RubyClip, :SimpleGuiCreator]
  new_path = File.dirname(__FILE__) + '/simple_gui_creator/' + SimpleGuiBootStrap.snake_case(clazz) + '.rb'
  autoload clazz, new_path
end