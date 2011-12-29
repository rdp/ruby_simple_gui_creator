require 'drive_info'
DriveInfo.create_looping_drive_cacher
DriveInfo.create_looping_drive_cacher
raise unless DriveInfo.get_dvd_drives_as_openstruct.length > 0