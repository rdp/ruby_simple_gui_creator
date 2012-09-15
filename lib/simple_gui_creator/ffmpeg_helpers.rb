require 'sane'

# NB requires a version of ffmpeg.exe to be in the path, and uses the first one it finds
module FfmpegHelpers
  # returns like {:audio => ['audio name 1', 'audio name 2'], :video => ['vid name 1', 'vid name 2' ]}
  # use like vid_names = FfmpegHelpers.enumerate_directshow_devices[:video]
  # use like   name = DropDownSelector.new(nil, vid_names, "Select audio device to capture and stream").go_selected_value
  def self.enumerate_directshow_devices
    ffmpeg_list_command = "ffmpeg -list_devices true -f dshow -i dummy 2>&1"
    enum = `#{ffmpeg_list_command}`
    unless enum.present?
      p 'failed', enum
	  sleep 1
	  enum = `#{ffmpeg_list_command}`
      out = '2nd try resulted in :' + enum
      p out
      #raise out # jruby and MRI both get here???? LODO...
    end

    audio = enum.split('DirectShow')[2]
    raise enum.inspect unless audio
    video = enum.split('DirectShow')[1]
	# TODO pass back index, too...
    audio_names = audio.scan(/"([^"]+)"/).map{|matches| matches[0]}
    video_names = video.scan(/"([^"]+)"/).map{|matches| matches[0]}
    {:audio => audio_names, :video => video_names}
  end
  
  def self.get_options_video_device name
    ffmpeg_get_options_command = "ffmpeg  -list_options true -f dshow -i video=\"#{name}\" 2>&1"
	enum = `#{ffmpeg_get_options_command}`
	out = []
	lines = enum.scan(/(pixel_format|vcodec)=([^ ]+)  min s=(\d+)x(\d+) fps=([^ ]+) max s=(\d+)x(\d+) fps=([^ ]+)$/)
	lines.map{|video_type, video_type_name, min_x, min_y, min_fps, max_x, max_y, max_fps|
	   {:video_type => video_type, :video_type_name => video_type_name, :min_x => min_x, 
	    :max_x => max_x, :max_y => max_y, max_fps => max_fps}
	}
  end
  
  def self.warmup_ffmpeg_so_itll_be_disk_cached 
    system "ffmpeg -list_devices true -f dshow -i dummy 2>&1"
  end
  
end
