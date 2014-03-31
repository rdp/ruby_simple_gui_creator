require 'sane'

# windows directshow ffmpeg wrapper helper

# NB requires a version of ffmpeg.{exe,bat} to be in the path or current working dir, and of course it will just use the first one it finds (cwd or then in the path
module FFmpegHelpers

  FFmpegNameToUse = 'ffmpeg' # can change it to whatever you want, like 'ffmpeg.exe' or 'full/path/ffmpeg.exe' or libav.exe

  # returns like {:audio => [['audio name 1', 0]], ['audio name 1', 1], ['audio name 2', 0], :video => ...}
  # use like vid_names = enumerate_directshow_devices[:video]
  # then could use like name = DropDownSelector.new(nil, vid_names, "Select audio device to capture and stream").go_selected_value
  def self.enumerate_directshow_devices
    ffmpeg_list_command = "#{FFmpegNameToUse} -list_devices true -f dshow -i dummy 2>&1"
    enum = `#{ffmpeg_list_command}`
	count = 0
    while !enum.present? || !enum.split('DirectShow')[2] # last part seems necessary for ffmpeg.bat files [?]
	  sleep 0.1 # sleep might not be needed.. = .
	  orig = enum
	  enum = `#{ffmpeg_list_command}`
      out = 'ffmpeg 2nd try enum resulted in :' + enum +' first was:' + orig
	  
      raise out if enum == '' && count == 20 # jruby and MRI both get here occasionally in error...suspected cmd.exe bug
	  count += 1
    end
    enum.gsub!("\r\n", "\n") # work around JRUBY-6913, which may no longer be needed...
    video = enum.split('DirectShow')[1]
	audio = enum.split('DirectShow')[2]
    
    audio_devices = parse_with_indexes audio
    video_devices = parse_with_indexes video
    out = {:audio => audio_devices, :video => video_devices}
	out
  end
  
  def self.video_device_present? device_and_idx
    all = enumerate_directshow_devices[:video]
	all.include?(device_and_idx)
  end
  
  # name is a non-escaped name, like video-screen-capture-device
  def self.get_options_video_device name, idx = 0
    ffmpeg_get_options_command = "#{FFmpegNameToUse} -list_options true -f dshow -i video=\"#{escape_for_input name}\" -video_device_number #{idx} 2>&1"
	enum = `#{ffmpeg_get_options_command}`
	out = []
	lines = enum.scan(/(pixel_format|vcodec)=([^ ]+)  min s=(\d+)x(\d+) fps=([^ ]+) max s=(\d+)x(\d+) fps=([^ ]+)$/)
	lines.map{|video_type, video_type_name, min_x, min_y, min_fps, max_x, max_y, max_fps|
	   {:video_type => video_type, :video_type_name => video_type_name, :min_x => min_x.to_i, :min_y => min_y.to_i,
	    :max_x => max_x.to_i, :max_y => max_y.to_i, :min_fps => min_fps.to_f, :max_fps => max_fps.to_f}
	}.uniq  # LODO actually starts with some duplicates ever? huh?
  end
  
  def self.warmup_ffmpeg_so_itll_be_disk_cached  # and hopefully faster later LODO this feels hackey
    Thread.new { 
	  system "#{FFmpegNameToUse} -list_devices true -f dshow -i dummy 2>&1" # outputs to stdout but...that's informative at times 
	}
  end
  
  # out_handle like the result of an IO.popen("ffmpeg ...", "w")
  # raises if it closes in less than expected_time (if set to something greater than 0, that is, obviously)
  def self.wait_for_ffmpeg_close out_handle, expected_time=0
    # requires updated version of jruby to work...Jruby lacks Process.waitpid currently for doze JRUBY-4354
	start_time = Time.now
    while !out_handle.closed?
      begin
	    if OS.jruby?
		  raise 'need jruby 1.7.0 for working Process.kill 0 (which we use) in windows...' unless JRUBY_VERSION >= '1.7.0'
		end
        Process.kill 0, out_handle.pid # ping it for liveness
	    sleep 0.1
	  rescue Errno::EPERM => e
	    # this can output twice in the case of one process piped to another? huh wuh?
	    puts 'detected ffmpeg is done [ping said so] in wait_for_ffmpeg_close method'
	    out_handle.close
	  end
    end
	elapsed = Time.now - start_time
	if (expected_time > 0) && (elapsed < expected_time) # XXX -1 default?
	  message = "ffmpeg failed too quickly, in #{elapsed}s"
	  puts message
	  raise message
	else
	  puts "ffmpeg exited apparently gracefully in #{elapsed}s > #{expected_time}"
	end
  end
  
  # screen capturer uses this
  # NB that it inserts a filter_complex [!]
  def self.combine_devices_for_ffmpeg_input audio_devices, video_device
   # XXX combine into same line??
   if audio_devices
     audio_device_string=audio_devices.map{|audio_device_name, audio_device_idx|
	   "-f dshow -audio_device_number #{audio_device_idx} -i audio=\"#{escape_for_input audio_device_name}\" "
	 }.join(' ')
	 audio_device_string = "#{audio_device_string} -filter_complex amix=inputs=#{audio_devices.length}" # though I guess amix is the wrong way to go here?
   end
   if video_device
     video_device_string="-f dshow -video_device_number #{video_device[1]} -i video=\"#{escape_for_input video_device[0]}\" "
   end
   " #{video_device_string} #{audio_device_string} "
  end
  
  private  
  
  def self.parse_with_indexes string
    names = []
	for line in string.lines
	  if line =~ /"(.+)"\n/
	    index = 0
		names << [$1, index]
	  elsif line =~ /repeated (\d+) times/
	    $1.to_i.times {
		  previous_name = names[-1][0]
		  index += 1
		  names << [previous_name, index]
		}
	  end
	end
	names
  end  
  
  def self.escape_for_input name
    name.gsub('"', '\\"') # for shell :)
  end
  
end

if $0 == __FILE__
 p FFmpegHelpers.enumerate_directshow_devices
 FFmpegHelpers.enumerate_directshow_devices[:video].each{|name| p name, FFmpegHelpers.get_options_video_device(name) }
end