require 'java'

# only plays wav/pcm and midi

class PlayAudio
  include_package 'javax.sound.sampled'
  import java.io.File;
  import java.io.IOException;
  Type = javax.sound.sampled.LineEvent::Type
  
  def initialize filename
    raise 'no filename?' unless filename
    @filename = filename
    @done = false
  end
  
  def warmup
    @audioInputStream = AudioSystem.getAudioInputStream(java.io.File.new @filename)
    @clip = AudioSystem.getClip
    @done = false
    @clip.add_line_listener { |line_event|
        if (line_event.get_type == Type::STOP || line_event.get_type == Type::CLOSE)
          @done = true;
          shutdown
        end
    }
    @clip.open(@audioInputStream)
  end
  
  def start
    warmup
    @clip.start
  end
  alias play start
  
  def loop
    warmup
    @clip.loop(Clip::LOOP_CONTINUOUSLY)
  end
    
  
  def join_finish
    while !@done
      sleep 0.01
    end
  end
  
  def shutdown
    @clip.close
    @audioInputStream.close
  end
  
  def stop
    @done = true
    shutdown
  end
end

if $0 == __FILE__
  p = PlayAudio.new ARGV[0]
  p.start
  p 'playing'
  sleep 2
  p.stop
  p.join_finish
  p 'silence'
  sleep 2
  p 'looping'
  p.loop
  sleep 2
  p.stop
  p 'silence'
  sleep 2
end