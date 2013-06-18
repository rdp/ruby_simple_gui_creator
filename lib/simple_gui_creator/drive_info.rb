=begin
Copyright 2010, Roger Pack 
This file is part of Sensible Cinema.

    Sensible Cinema is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Sensible Cinema is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Sensible Cinema.  If not, see <http://www.gnu.org/licenses/>.
=end

require 'os'
require 'ostruct'
require 'thread'

class DriveInfo

  def self.md5sum_disk(dir)
   if OS.mac?
     exe = "#{__DIR__}/../../vendor/mac_dvdid/bin/dvdid"
   else
     exe = "#{__DIR__}/../../vendor/dvdid.exe"
   end
   raise exe + '--exe doesnt exist?' unless File.exist? exe
   command = "#{exe} \"#{dir}\""
   output = `#{command}` # this can take like 2.2s to spin up the disk...
   raise 'dvdid command failed?' + command  + " with output:" + output unless $?.exitstatus == 0
   output.strip
  end

  @@drive_cache = nil
  @@drive_cache_mutex = Mutex.new
  @@drive_changed_notifies = []
  def self.create_looping_drive_cacher
    # has to be in its own thread or wmi will choke...
    looped_at_least_once = false
    if @caching_thread
      looped_at_least_once = true
    else
      @caching_thread = Thread.new {
        # use a dir glob to avoid having to use wmi too frequently (or accessing disks too often, which we might still be doing accidentally anyway)
        if OS.doze?
    		  old_drive_glob = '{' + DriveInfo.get_dvd_drives_even_if_no_disc_present.map{|dr| dr.MountPoint[0..0]}.join(',') + '}:/.' # must be in the thread for wmi
        else
          old_drive_glob = '/Volumes/*'
        end
        previously_known_about_discs = nil
        loop {
  	      should_update = false
          @@drive_cache_mutex.synchronize { # in case the first update takes too long, basically, so they miss it LODO still a tiny race condition in here...might be useless...
            looped_at_least_once = true # let the spawning waiting thread exit quickly
            cur_disks = Dir[old_drive_glob]
    		    if cur_disks != previously_known_about_discs
  	          p 'updating disk lists...'
  			      should_update = true
              @@drive_cache = get_all_drives_as_ostructs_internal
              previously_known_about_discs = cur_disks
  		      end
          }
          notify_all_drive_blocks_that_change_has_occured if should_update
          sleep 0.5
        }
      }
    end
    # maintain some thread startup sanity :P
    while(!looped_at_least_once)
      sleep 0.01
    end
    true
  end

  @@updating_mutex = Mutex.new # theoretically 2 threads could call this at once...so synchronize it...
  def self.notify_all_drive_blocks_that_change_has_occured
    @@updating_mutex.synchronize {
      @@drive_changed_notifies.each{|block| block.call}
    }
  end

 def self.add_notify_on_changed_disks &block
  raise unless block
  @@drive_changed_notifies << block
  should_call = false
  @@drive_cache_mutex.synchronize { should_call = true if @@drive_cache }
  block.call if should_call # should be called at least once, right, on init?
  true
 end

 def self.get_dvd_drives_as_openstruct
   disks = get_all_drives_as_ostructs
   disks.select{|d| d.Description =~ /CD-ROM/ && File.exist?(d.Name + "/VIDEO_TS")}
 end
 
  
 def self.get_drive_with_most_space_with_slash
  disks = get_all_drives_as_ostructs
  most_space = disks.sort_by{|d| d.FreeSpace}[-1]
  most_space.MountPoint + "/"
 end

 def self.get_all_drives_as_ostructs # gets all drives not just DVD drives...
  @@drive_cache_mutex.synchronize {
    if @caching_thread
      @@drive_cache
    else
      get_all_drives_as_ostructs_internal # first time through for the startup thread goes here too
    end
  }
 end

 private

 def self.get_dvd_drives_even_if_no_disc_present # private since it uses internal
   raise unless OS.doze? # no idea how to do this in mac :P
   disks = get_all_drives_as_ostructs_internal
   disks.select{|d| d.Description =~ /CD-ROM/}
 end

  # DevicePoint is like "where to point mplayer at this succer"
  def self.get_all_drives_as_ostructs_internal
    if OS.mac?
      require 'plist'
      Dir['/Volumes/*'].map{|dir|
       parsed = Plist.parse_xml(`diskutil info -plist "#{dir}"`)
	   next unless parsed # some odd mount points like /Volumes/SugarSync have no output...
       d2 = OpenStruct.new
       d2.VolumeName = parsed["VolumeName"]
       d2.Name = dir # DevNode?
       d2.FreeSpace = parsed["FreeSpace"].to_i
       d2.Description = parsed['OpticalDeviceType']
       d2.MountPoint = parsed['MountPoint']
       if d2.MountPoint == '/'
         # try to guess a more writable default location...this works I guess?
         d2.MountPoint = File.expand_path '~'
       end
       d2.DevicePoint = parsed['DeviceNode'].sub('disk', 'rdisk') # I've heard using rdisk is better/faster...
       d2
      }.compact
    else
      require 'ruby-wmi'
      disks = WMI::Win32_LogicalDisk.find(:all)
      out = disks.map{|d| d2 = OpenStruct.new
        d2.Description = d.Description
        d2.VolumeName = d.VolumeName
        d2.Name = d.Name
        d2.FreeSpace = d.FreeSpace.to_i
        d2.MountPoint = d.Name[0..2] # like f:\
        d2.DevicePoint = d2.MountPoint
        d2
      }
      disks.each{|d| d.ole_free} # require rdp-ruby-wmi to not leak here, even with this ole_free...
      out
    end
  end
end

if $0 == __FILE__
  p DriveInfo.get_dvd_drives_as_openstruct
end
