# translation from http://introcs.cs.princeton.edu/java/faq/mp3/MP3.java.html

require 'java'
require File.dirname(__FILE__) + '/../ext/jl1.0.1.jar' # third party jlayer mp3 jar <sigh>

class PlayMp3Audio 
   java_import "javazoom.jl.player.Player"
   
   def initialize filename # does not work with .wav, unfortunately...
     @filename = filename
   end
   
   def start
      raise 'file not found?' unless File.exist? @filename
      fis     = java.io.FileInputStream.new(@filename)
      bstream = java.io.BufferedInputStream.new(fis)
      @player = Player.new(bstream)
			@thread = Thread.new { 
			  @player.play 
			}			
   end
   
   def join
     @thread.join
   end
   
   def play_till_end
     start
	 join
   end
   
   alias play_non_blocking start
   
   def stop
     if @player
       @player.close # at least they give us this method yikes
	   @player = nil
	 end
	 # raising here means you didn't call 
   end
   
end