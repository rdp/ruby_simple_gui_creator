require 'java'

class PlayAudio
  import "sun.audio.AudioStream"
  SunAudio = AudioStream
  import "sun.audio.AudioDataStream"
  import "sun.audio.AudioPlayer"
  SunAudioPlayer = AudioPlayer
  import "sun.audio.ContinuousAudioDataStream"
  
  private
  def self.play filename
    i = java.io.FileInputStream.new(filename)
    a = AudioStream.new(i)
    SunAudioPlayer.player.start(a)
    a
  end
  
  def self.loop filename
    i = java.io.FileInputStream.new(filename)
    a = AudioStream.new(i)
    b = a.get_data # failing means too big of data...
    c = ContinuousAudioDataStream.new(b)
    SunAudioPlayer.player.start(c)
    c
  end
  
  def self.stop audio_stream
    SunAudioPlayer.player.stop audio_stream
  end
  
  public
  def initialize filename
    @filename = filename
  end
  
  def start
    raise if @audio_stream
    @audio_stream = PlayAudio.play @filename
  end
  
  def loop # will fail for stream > 1 MB
    raise if @audio_stream
    @audio_stream = PlayAudio.loop @filename
  end
  
  def stop
    raise unless @audio_stream
    PlayAudio.stop @audio_stream
    @audio_stream = nil
  end
    
end

if $0 == __FILE__ # unit tests :)
 puts 'syntax: filename.wav less than 1MB'
 a = PlayAudio.new ARGV[0]
 a.start
 sleep 1
 a.stop
 p 'silence'
 sleep 1
 p 'resume, looping'
 a = PlayAudio.new ARGV[0]
 a.loop
 sleep 5
 a.stop
 p 'silence'
 sleep 1
 p 'resume normal'
 a = PlayAudio.new ARGV[0]
 a.start
 sleep 2
 a.stop
end