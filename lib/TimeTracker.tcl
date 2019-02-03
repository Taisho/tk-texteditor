namespace eval TimeTracker {

    #handler for the ticking code
    variable hafter -1 
    variable seconds 0

    proc open {} {
        set w .timeTracker
        if {[winfo exists $w]} {
            focus $w
            return
        }
        toplevel $w
        wm title $w "Time Tracker"

        pack [button .timeTracker.toggle -command "TimeTracker::toggle" -text "Start!"] -side right
        pack [label .timeTracker.tLabel -text "00:00:00"] -side right
    }

    proc toggle {} {
        variable hafter
        variable seconds
        
        if {$hafter == -1} {
          .timeTracker.toggle configure -text "Stop!"
          set hafter [after 1000 TimeTracker::tick]
        } else {
          after cancel $hafter
          set hafter -1
          .timeTracker.toggle configure -text "Start!"
        }
    }

    proc tick {} {
        variable seconds
        variable hafter

        incr seconds 
        set time [clock format $seconds -format "%H:%M:%S"]
        .timeTracker.tLabel configure -text $time

        set hafter [after 1000 TimeTracker::tick]
    }

}
