require 'sane'

# windows directshow ffmpeg helper

# NB requires a version of ffmpeg.{exe,bat} to be in the path or current working dir, and of course it will just use the first one it finds (cwd or then in the path
module FFmpegHelpers
  # returns like {:audio => ['audio name 1', 'audio name 2'], :video => ['vid name 1', 'vid name 2' ]}
  # use like vid_names = enumerate_directshow_devices[:video]
  # then could use like name = DropDownSelector.new(nil, vid_names, "Select audio device to capture and stream").go_selected_value
  def self.enumerate_directshow_devices
    ffmpeg_list_command = "ffmpeg -list_devices true -f dshow -i dummy 2>&1"
    enum = `#{ffmpeg_list_command}`
	count = 0
    while !enum.present? || !enum.split('DirectShow')[2] # last part seems necessary for ffmpeg.bat files [?]
	  sleep 0.1 # sleep might not be needed.. = .
	  orig = enum
	  enum = `#{ffmpeg_list_command}`
      out = 'ffmpeg 2nd try enum resulted in :' + enum +' first was:' + orig
	  
      raise out if enum == '' && count == 20 # jruby and MRI both get here...suspected cmd.exe bug
	  count += 1
    end
    enum.gsub!("\r\n", "\n") # work around JRUBY-6913
    video = enum.split('DirectShow')[1]
	audio = enum.split('DirectShow')[2]
    
    audio_names = parse_with_indexes audio
    video_names = parse_with_indexes video
    out = {:audio => audio_names, :video => video_names}
	p out
	out
  end
  
  def self.parse_with_indexes string
    names = [] # video_device_number
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
    name.gsub('"', '\\"')
  end
  
  # name is a non-escaped name, like video-screen-capture-device
  def self.get_options_video_device name
    ffmpeg_get_options_command = "ffmpeg  -list_options true -f dshow -i video=\"#{escape_for_input name}\" 2>&1"
	enum = `#{ffmpeg_get_options_command}`
	out = []
	lines = enum.scan(/(pixel_format|vcodec)=([^ ]+)  min s=(\d+)x(\d+) fps=([^ ]+) max s=(\d+)x(\d+) fps=([^ ]+)$/)
	lines.map{|video_type, video_type_name, min_x, min_y, min_fps, max_x, max_y, max_fps|
	   {:video_type => video_type, :video_type_name => video_type_name, :min_x => min_x.to_i, :min_y => min_y.to_i,
	    :max_x => max_x.to_i, :max_y => max_y.to_i, :min_fps => min_fps.to_f, :max_fps => max_fps.to_f}
	}.uniq  # LODO some duplicates?
  end
  
  def self.warmup_ffmpeg_so_itll_be_disk_cached 
    system "ffmpeg -list_devices true -f dshow -i dummy 2>&1" # outputs to stdout but...that's informative sometimes
  end
  
  def self.wait_for_ffmpeg_close out_handle # like the result of IO.popen("ffmpeg ...", "w")
    # requires some funky version of jruby to work...
    while !out_handle.closed?
      begin
	    if OS.jruby?
		  raise 'need jruby 1.7.0 for working Process.kill 0 in windows' unless JRUBY_VERSION >= '1.7.0'
		end
        Process.kill 0, out_handle.pid # ping it
	    sleep 0.2
	  rescue Errno::EPERM => e
	    puts 'detected ffmpeg is done'
	    out_handle.close
	  end
    end
  end
  
  
def self.combine_devices_for_ffmpeg_input audio_device, video_device
 if audio_device
   audio_device="-f dshow -i audio=\"#{FFmpegHelpers.escape_for_input audio_device}\""
 end
 if video_device
   video_device="-f dshow -i video=\"#{FFmpegHelpers.escape_for_input video_device}\""
 end
 "#{video_device} #{audio_device}"
end
  
end

if $0 == __FILE__
 p FFmpegHelpers.enumerate_directshow_devices
 FFmpegHelpers.enumerate_directshow_devices[:video].each{|name| p name, FFmpegHelpers.get_options_video_device(name) }
end