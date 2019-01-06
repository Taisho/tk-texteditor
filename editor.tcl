#!/usr/bin/wish


package require Tcl 8.5
package require snit 2.3.2

source lib/TclParser.tcl

global tabs
global currentTab -1
global currentTextWidget -1
global lastTabIndex -1


proc openFile {} {
    global lastTabIndex
    global tabs
    global currentTab
    global currentTextWidget

    # If no file was selected, don't do anything
    set filePath [tk_getOpenFile]
    if { $filePath == "" } {
        return
    }

    # Now check if the file was already opened and loaded in memory
   set existingTab {}
   foreach {key value} [array get tabs] {
       puts "key: $key"
        puts "regexp: [regexp {(.+),(.+)} $key -> tabIndex prop]"
       puts "tabIndex and prop: '$tabIndex' '$prop'"

        if {[string compare $prop filePath] == 0 && [string compare $filePath tabs($key)] == 0} {
           set existingTab $tabIndex 
           puts "set existing tab $tabIndex"
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

    .notebook select $textWidget
    puts "tabId: $tabId"

    $textWidget delete 1.0 end
    $textWidget insert end $contents
    Tcl::apply_syntax_tk $textWidget "Tcl";
    Tcl::parse_text $textWidget "Tcl"

    set tabs($lastTabIndex,widgetPath) $textWidget
    set tabs($lastTabIndex,filePath) $filePath
    set currentTextWidget $textWidget
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
pack [ttk::frame .toolbar] -fill x
pack [button .toolbar.open -command { openFile } -text "Open"] -anchor nw
pack [ttk::notebook .notebook] -expand yes -fill both
pack [ttk::frame .statusbar] -fill x
pack [label .statusbar.label -text "Some info"] -anchor nw

bind .notebook <<NotebookTabChanged>> { tabChanged }
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
menu .menubar
. configure -menu .menubar
set m .menubar
menu $m.file
menu $m.edit
$m add cascade -menu $m.file -label File
$m add cascade -menu $m.edit -label Edit

$m.file add command -label "New" -command "newFile"	
$m.file add command -label "Open..." -command "openFile"
$m.file add command -label "Close" -command "closeFile"
$m.file add separator
$m.file add command -label "Quit" -command "quit"

#pack [button .btn -text "Parse" -command { Tcl::parse_text $currentTextWidget "Tcl"}]

