require 'common.rb'
require_relative '../play_mp3_audio.rb'

describe PlayMp3Audio do

  it "can play mp3 files" do
    a = PlayMp3Audio.new 'diesel.mp3'
	a.play
	puts 'non silence'
	sleep 1
	a.stop
	puts 'silence'
	sleep 1
  end
  
  it "can join" do
    a = PlayMp3Audio.new 'diesel.mp3'
	a.play_till_end 
  end
  
  it "can play wav" do
    require_relative '../play_audio.rb'
	a = PlayAudio.new 'static.wav'
	a.start
	puts 'static'
	sleep 1
	puts 'silence'
	a.stop
	sleep 1
  end

end