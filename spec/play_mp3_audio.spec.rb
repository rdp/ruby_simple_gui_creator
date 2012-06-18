require 'common.rb'

# also test PlayAudio
describe PlayMp3Audio do

  it "can play mp3 files" do
    a = PlayMp3Audio.new 'diesel.mp3'
	a.play_non_blocking
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
	a = PlayAudio.new 'static.wav'
	a.start
	puts 'static'
	sleep 1
	puts 'silence'
	a.stop
	sleep 1
  end

end