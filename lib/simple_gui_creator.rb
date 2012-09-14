
module SimpleGuiCreator
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

require File.dirname(__FILE__) + '/simple_gui_creator/simple_gui_creator_main.rb'

# some autoloads, in case they save any load time...
# not in the SGC namespace since they're somewhat separate from GUI control...which seems a bit weird...
for clazz in [:FfmpegHelpers, :DriveInfo, :MouseControl, :PlayAudio, :PlayMp3Audio, :RubyClip, :Storage]
  new_path = File.dirname(__FILE__) + '/simple_gui_creator/' + SimpleGuiCreator.snake_case(clazz) + '.rb'
  autoload clazz, new_path
end

module SimpleGuiCreator
  autoload :ParseTemplate, File.dirname(__FILE__) + '/simple_gui_creator/parse_template.rb'
end