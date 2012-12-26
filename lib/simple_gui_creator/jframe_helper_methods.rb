require 'java'

# helper/english friendlier methods for JFrame

class javax::swing::JFrame

   java_import javax::swing::JFrame # so we can refer to it as JFrame, without polluting the global namespace

   java_import java.awt.event.ActionListener
   
   #class StateListener
   #  include java.awt.event.WindowListener	
   #end
  
   class CloseListener < java.awt.event.WindowAdapter
     def initialize parent, &block
	   super()
	   @parent = parent
	   @block = block
	 end
	 
     def windowClosed event # sometimes this, sometimes the other...
	   if @block
	    b = @block # force avoid calling it twice, since swing does seem to call this method twice, bizarrely
		@block = nil
		b.call
	   end
	 end
	 
	 def windowClosing event
	    #p 'windowClosing' # hitting the X goes *only* here, and twice? ok this is messed up
		@parent.dispose
	 end
   end
   
   def initialize *args
     super(*args) # we do always get here...
	 # because we do this, you should *not* have to call the unsafe:
	 # setDefaultCloseOperation(EXIT_ON_CLOSE)
	 # which basically does a System.exit(0) when the last jframe closes. Yikes jdk, yikes.	 
	 #addWindowListener(CloseListener.new(self))
     dispose_on_close # don't keep running after being closed, and otherwise prevent the app from exiting! whoa!
   end   
   
   def close
     dispose # <sigh>
   end
   
   alias close! close
   
   def dispose_on_close
     setDefaultCloseOperation JFrame::DISPOSE_ON_CLOSE
   end

  # NB this can only be called at most once per frame...at least...with dispose on close, not sure about the others...
   def after_closed &block
	 addWindowListener(CloseListener.new(self) {
	   block.call
	 })
   end
   
   def after_minimized &block
    addWindowStateListener {|e|
	  if e.new_state == java::awt::Frame::ICONIFIED
        block.call	  
	  else
	    #puts 'non restore'
	  end
	}
   end
      
   def after_restored_either_way &block
    addWindowStateListener {|e|
	  if e.new_state == java::awt::Frame::NORMAL
        block.call	  
	  else
	    #puts 'non restore'
	  end
	}
   end  
  
   def bring_to_front # kludgey...but said to work for swing frames...
    java.awt.EventQueue.invokeLater{
      unminimize
      toFront
      repaint
    }      
   end
   alias bring_to_front! bring_to_front
   
   def minimize
     setState(java.awt.Frame::ICONIFIED)
   end
   
   alias minimize! minimize
  
   def restore
     setState(java.awt.Frame::NORMAL) # this line is probably enough, but do more just in case...
     #setVisible(true)
   end
   alias restore! restore
  
   alias unminimize restore
   alias unminimize! restore
   
   def maximize
     setExtendedState(JFrame::MAXIMIZED_BOTH)
   end
   alias maximize! maximize
   
   # avoid jdk6 always on top bug http://betterlogic.com/roger/2012/04/jframe-setalwaysontop-doesnt-work-after-using-joptionpane/
   alias always_on_top_original always_on_top=
  
   def always_on_top=bool 
    always_on_top_original false
    always_on_top_original bool
   end

   def set_always_on_top bool
      always_on_top=bool
   end
  
   def setAlwaysOnTop bool
      always_on_top=bool
   end
  
  end # class JFrame
  