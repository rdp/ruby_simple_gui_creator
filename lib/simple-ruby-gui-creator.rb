# just autoload everything always :)

module SimpleRubyGuiCreator
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

for clazz in [:DriveInfo, :MouseControl, :ParseTemplate, :PlayAudio, :PlayMp3Audio, :RubyClip, :SwingHelpers]
  new_path = File.dirname(__FILE__) + '/simple-ruby-gui-creator/' + SimpleRubyGuiCreator.snake_case(clazz) + '.rb'
  autoload clazz, new_path
end