#!/usr/bin/wish


package require Tcl 8.5
package require snit 2.3.2

source lib/Recognizer.tcl

global tabs
global currentTab -1
global currentTextWidget -1
global lastTabIndex 0

namespace eval Calendar {
    proc contextMenu {x y} {
        tk_popup .calendar.contextMenu $x $y
    }

    proc openPreferences {} {
        set w .calendarPreferences
        if {[winfo exists $w]} {
            focus $w
            return
        }
        toplevel $w
        wm title $w "Calendar Preferences"

        pack [canvas $w.canvas -width 300 -height 120] -anchor nw
    }
}


proc openCalendar {} {
    if {[winfo exists .calendar]} {
        focus .calendar
        return
    }
    toplevel .calendar
    #TODO check if the calendar window was already open and if yes, focus it
    wm title .calendar "Calendar"
    wm resizable .calendar 0 0

    menu .calendar.contextMenu -tearoff 0
    .calendar.contextMenu add command -accelerator "Ctrl+C" -label "Copy" -command { copySelection }

    set m [menu .calendar.menu -relief flat]
    .calendar configure -menu $m
    menu $m.file
    $m add cascade -menu $m.file -label File

    $m.file add command -accelerator "Ctrl+p" -label "Preferences Ctrl-P" -command "Calendar::openPreferences"	
    bind .calendar <Control-p> { Calendar::openPreferences }

    set systemTime [clock seconds]
    set month [clock format $systemTime -format "%b"]
    set monthNum [clock format $systemTime -format "%N"]
    set year [clock format $systemTime -format "%Y"]
    set nextYear [expr "$year+1"]

    # Get epoch seconds of the first day of the month (at 00:00)
    set beginMonth [clock scan "$year-$month-01" -format "%Y-%b-%d"] 
    set weekDay [clock format $beginMonth -format "%a"]

    set firstMonday ""
    set offset 0

    switch $weekDay {
        Mon { set offset 0 }
        Tue { set offset -1 }
        Wed { set offset -2 }
        Thu { set offset -3 }
        Fri { set offset -4 }
        Sat { set offset -5 }
        Sun { set offset -6 }
    }

    set beginCalendar [expr $beginMonth+60*60*24*$offset]

    for {set i 0; set x 0; set y 0; set continue 1; set curday $beginCalendar} {
        $continue == 1} {} {
        set weekDay [clock format $curday -format "%a"]
        set day [clock format $curday -format "%d"]
        set curMonNum [clock format $curday -format "%N"]
        set curYear [clock format $curday -format "%Y"]

        if {(($curYear == $year && $curMonNum > $monthNum) || \
            ($curYear > $year && $curMonNum != $monthNum)) && \
            [string compare $weekDay Mon] == 0} {
            set continue 0
            continue
        }

        grid [canvas .calendar.widg$i -width 75 -height 75] -column $x -row $y
        .calendar.widg$i create text 10 30 -anchor w -font Purisa -text "${day}th"
        .calendar.widg$i create rect 0 75 75 75 -outline #000 -fill #000
        .calendar.widg$i create rect 77 0 75 75 -outline #000 -fill #000
        #.calendar.widg$i insert end "$day - $weekDay"

        bind .calendar.widg$i <3> "Calendar::contextMenu %X %Y"

        if {$x >= 6} {
            incr y
            set x 0
        } else {
            incr x
        }

        incr i
        set curday [expr $curday+60*60*24]
    }
}

proc saveFile {} {
    set filePath 
    set channel [open $filePath w]
    puts -nonewline $channel $contents
    close $channel
}

proc openFile {{file ""}} {
    global lastTabIndex
    global tabs
    global currentTab
    global currentTextWidget

    
    # If no file was selected, don't do anything
    if {$file == ""} {
        set filePath [tk_getOpenFile]
        if { $filePath == "" } {
            return
        }
    } else {
        set filePath $file
    }


    # Now check if the file was already opened and loaded in memory
   set existingTab {}
   foreach {key value} [array get tabs] {

        if {[string compare $value filePath] == 0 && [string compare $filePath $tabs($key)] == 0} {
           set existingTab $tabIndex 
        }
    } 

    wm title . "$filePath - Fox"

    if { $existingTab != {} } {
        .notebook select $existingTab
        return
    }

    set channel [open $filePath r]
    set contents [read $channel]
    close $channel

    regexp {([^/]+)$} $filePath -> basename 
    incr lastTabIndex
    set textWidget [text .notebook.tw$lastTabIndex]
    .notebook add $textWidget -text $basename
    set tabId [.notebook index .notebook.tw$lastTabIndex]

    bind $textWidget <3> { contextMenu %X %Y}

    .notebook select $textWidget

    $textWidget delete 1.0 end
    $textWidget insert end $contents
    Core::recognize_parse $filePath $textWidget

    set tabs($lastTabIndex,widgetPath) $textWidget
    set tabs($lastTabIndex,filePath) $filePath
    set currentTextWidget $textWidget
}

proc newFile {} {
    global lastTabIndex
    global tabs
    global currentTab
    global currentTextWidget

    wm title . "*New File* - Fox"

    set filePath ""
    incr lastTabIndex
    set textWidget [text .notebook.tw$lastTabIndex]
    set basename "*New*"
    .notebook add $textWidget -text $basename
    set tabId [.notebook index .notebook.tw$lastTabIndex]

    bind $textWidget <3> { contextMenu %X %Y}
    .notebook select $textWidget

    set contents ""
    $textWidget delete 1.0 end
    $textWidget insert end $contents
    Core::recognize_parse $filePath $textWidget

    set tabs($lastTabIndex,widgetPath) $textWidget
    set tabs($lastTabIndex,filePath) $filePath
    set currentTextWidget $textWidget
}

proc createContextMenu {} {
    menu .contextMenu -tearoff no

    .contextMenu add command -accelerator "Ctrl+C" -label "Copy" -command { copySelection }
}

createContextMenu

proc contextMenu {x y} {
    tk_popup .contextMenu $x $y
}

proc tabChanged {} {
}

proc closeFile {} {
    global tabs
    global currentTextWidget

    set tabId [.notebook index $currentTextWidget]
    unset tabs($tabId,widgetPath)
    unset tabs($tabId,filePath)

    .notebook forget current
    unset
}

proc quit {} {
    exit
}

wm title . "Fox"
wm geometry . 640x480
pack [ttk::frame .toolbar] -fill x
image create photo iconNewFile -file "icons/page.png"
pack [button .toolbar.new -relief flat -overrelief raised -command { newFile } -image iconNewFile -text New -compound top] -anchor nw -side left
image create photo iconOpenFile -file "icons/folder_page.png"
pack [button .toolbar.open -relief flat -overrelief raised -command { openFile } -image iconOpenFile -text Open... -compound top] -anchor nw -side left
image create photo iconSaveFile -file "icons/page_save.png"
pack [button .toolbar.save -relief flat -overrelief raised -command { saveFile } -image iconSaveFile -text Save -compound top] -anchor nw -side left
pack [button .toolbar.saveas -relief flat -overrelief raised -command { saveFile } -image iconSaveFile -text "Save As..." -compound top] -anchor nw -side left

pack [ttk::notebook .notebook] -expand yes -fill both
pack [ttk::frame .statusbar] -fill x
pack [label .statusbar.label -text "Some info"] -anchor nw

bind .notebook <<NotebookTabChanged>> { tabChanged }
bind .notebook <Double-1> { newFile }
# //
# // NOTE when passing accross Tk widget to
# // a procedures, don't upvar it, as Tk
# // widget identifiers are not variables
# // (rather procedures)
# //

# // Here we are placing the menu to the top of the main window
# // This is where we will put menu items such as "File -> Open",
# // "File -> Save", "File -> Save As..." and so on.
option add *tearOff 0
menu .menubar -relief flat
. configure -menu .menubar
set m .menubar
menu $m.file
menu $m.edit
menu $m.journal
menu $m.computer
$m add cascade -menu $m.file -label File
$m add cascade -menu $m.edit -label Edit
$m add cascade -menu $m.journal -label Journal
$m add cascade -menu $m.computer -label Computer

# // Doing menus
#
# File Menu
$m.file add command -accelerator "Ctrl+n" -label "New" -command "newFile"	
bind . <Control-n> { newFile }

$m.file add command -accelerator "Ctrl+o" -label "Open..." -command "openFile"
bind . <Control-o> { openFile }
$m.file add command -accelerator "Ctrl+s" -label "Save" -command "saveFile"
bind . <Control-s> { saveFile }
$m.file add command -accelerator "Ctrl+w" -label "Close" -command "closeFile"

$m.file add separator

$m.file add command -accelerator "Ctrl+q" -label "Quit" -command "quit"
bind . <Control-q> { exit }



#Edit Menu
$m.edit add command -accelerator "Ctrl+c" -label "Copy" -command "copy"	
bind . <Control-c> { copy }

$m.edit add command -accelerator "Ctrl+v" -label "Paste" -command "paste"	
bind . <Control-v> { paste }

$m.edit add separator

$m.edit add command -accelerator "Ctrl+p" -label "Preferences" -command "openPreferences"	
bind . <Control-p> { openPreferences }




# Journal Menu
$m.journal add command -accelerator "Ctrl+g" -label "Calendar..." -command "openCalendar"	
#pack [button .btn -text "Parse" -command { Tcl::parse_text $currentTextWidget "Tcl"}]




# Computer Menu
$m.computer add command -label "File Manager" -command "FileManager::open"	
$m.computer add command -label "Diagnosis" -command "Diagnosis::open"	
#pack [button .btn -text "Parse" -command { Tcl::parse_text $currentTextWidget "Tcl"}]



# End of menu initialization


if {$argc > 0} {
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        if {[file exists $arg]} {
            openFile $arg
        }
    }
}

