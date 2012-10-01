require 'sane'

# NB requires a version of ffmpeg.{exe,bat} to be in the path or current working dir, and of course it will just use the first one it finds (cwd or then in the path
module FfmpegHelpers # LODO rename
  # returns like {:audio => ['audio name 1', 'audio name 2'], :video => ['vid name 1', 'vid name 2' ]}
  # use like vid_names = FfmpegHelpers.enumerate_directshow_devices[:video]
  # use like   name = DropDownSelector.new(nil, vid_names, "Select audio device to capture and stream").go_selected_value
  def self.enumerate_directshow_devices
    ffmpeg_list_command = "ffmpeg -list_devices true -f dshow -i dummy 2>&1"
    enum = `#{ffmpeg_list_command}`
	count = 0
    while !enum.present? || !enum.split('DirectShow')[2] # last part seems necessary for ffmpeg.bat files [?]
	  sleep 0.1 # sleep might not be needed.. = .
	  orig = enum
	  enum = `#{ffmpeg_list_command}`
      out = 'ffmpeg 2nd try enum resulted in :' + enum +' first was:' + orig
	  
      raise out if enum == '' && count == 20 # jruby and MRI both get here without the cou???? LODO...
	  count += 1
    end
    enum.gsub!("\r\n", "\n") # work around JRUBY-6913
    audio = enum.split('DirectShow')[2]
    video = enum.split('DirectShow')[1]
	# TODO pass back indexes, too...
    audio_names = audio.scan(/"(.+)"\n/).map{|matches| matches[0]}
    video_names = video.scan(/"(.+)"\n/).map{|matches| matches[0]}
    {:audio => audio_names, :video => video_names}
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
	}
  end
  
  def self.warmup_ffmpeg_so_itll_be_disk_cached 
    system "ffmpeg -list_devices true -f dshow -i dummy 2>&1"
  end
  
end

if $0 == __FILE__
 p FfmpegHelpers.enumerate_directshow_devices
 FfmpegHelpers.enumerate_directshow_devices[:video].each{|name| p name, FfmpegHelpers.get_options_video_device(name) }
end