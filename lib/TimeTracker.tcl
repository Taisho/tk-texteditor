namespace eval TimeTracker {

    #handler for the ticking callback
    variable hafter -1 
    variable seconds 0
    variable buttonToggle .timeTracker.frame1.toggle
    variable labelTime .timeTracker.frame1.labelTime
    variable comboBox .timeTracker.frame1.comboBox
    variable tree .timeTracker.frame2.treeView

    proc open {} {
        set w .timeTracker
        if {[winfo exists $w]} {
            focus $w
            return
        }
        toplevel $w
        wm title $w "Time Tracker"
        wm geometry $w 250x70

        pack [frame .timeTracker.frame1] -side top -expand yes -fill x
        pack [frame .timeTracker.frame2] -side top -expand yes -fill both

        ui_controls
        ui_treeview
    }

    proc ui_controls {} {
        variable buttonToggle
        variable labelTime
        variable comboBox

        pack [button $buttonToggle -command "TimeTracker::toggle" -text "Start!"] -side right
        pack [label $labelTime -text "00:00:00"] -side right
        pack [ttk::combobox $comboBox] -side right
    }

    proc ui_treeview {} {
        variable tree 
        pack [ttk::treeview $tree] -side top -expand yes -fill both

        $tree configure -columns "task start end length"
        $tree heading task -text "Task Name"
        $tree heading start -text "Start Time"
        $tree heading end -text "End Time"
        $tree heading length -text "Duration"
        
        $tree column #0 -width 1
        $tree column #0 -stretch no

        $tree insert {} end -id widgets -text {} -values [list "Kreut" "12:10" "13:00" "00:50"]
    }

    proc toggle {} {
        variable hafter
        variable seconds
        variable $buttonToggle
        
        if {$hafter == -1} {
          $buttonToggle configure -text "Stop!"
          set hafter [after 1000 TimeTracker::tick]
        } else {
          after cancel $hafter
          set hafter -1
          $buttonToggle configure -text "Start!"
        }
    }

    proc tick {} {
        variable seconds
        variable hafter
        variable labelTime

        incr seconds 
        set time [clock format $seconds -gmt yes -format "%H:%M:%S"]
        $labelTime configure -text $time

        # 'after' resembles JavaScript's setTimeOut(), not setInterval()
        # so we need to assign our callback for future execution every
        # time it runs
        set hafter [after 1000 TimeTracker::tick]
    }

    proc write {} {

    }
}
