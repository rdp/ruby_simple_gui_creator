require 'java'

class PlayAudio2
  include_package 'javax.sound.sampled'
  import java.io.File;
  import java.io.IOException;
  Type = javax.sound.sampled.LineEvent::Type
  
  def initialize filename
    raise unless filename
    @filename = filename
    @done = false
  end
  
  def start
    audioInputStream = AudioSystem.getAudioInputStream(java.io.File.new @filename)
    clip = AudioSystem.getClip
    @done = false
    clip.add_line_listener { |line_event|
        puts line_event.get_type
        if (line_event.get_type == Type::STOP || line_event.get_type == Type::CLOSE)
          @done = true;
          clip.close
          audioInputStream.close
        end
    }
    clip.open(audioInputStream)
    clip.start
  end
  
  def join_finish
    while !@done
      sleep 0.01
    end
  end
  
  def stop
    @done = true
  end
end

if $0 == __FILE__
  p = PlayAudio2.new ARGV[0]
  p.start
  p 'waiting'
  sleep 1
  p.stop
  p.join_finish
  p 'done'
end