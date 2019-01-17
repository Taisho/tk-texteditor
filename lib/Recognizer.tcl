source lib/TclParser.tcl
source lib/TclParser.tcl

namespace eval Core {

    # procedure recognize_parse first recognizes buffer's language (or type) and then
    # parses that buffer with that language's rules
    proc recognize_parse {filename textwidget} {
        # Variables:
        # $type      -  buffer's type. Gets populated along the way
        set type ""
       # Tcl::apply_syntax_tk $textWidget "Tcl";
       # Tcl::parse_text $textWidget "Tcl"
        set firstline [$textwidget get 0.1 end];

        set exten ""
        regexp {\..*$} $filename -> exten

        if {$exten != ""} {
            set exten [string tolower $exten]
            switch $exten {
               "tcl" {set type "Tcl"}
               "md" {set type "MarkDown"}
            }
        } else {
            if {[regexp {^#!/} $firstline m]} {
                if {[regexp {^\S+/env (\S+)} $firstline -> command] == 0} {
                    regexp {^\S+/([^/\s]+)\s?} $firstline -> command
                }

                switch $command {
                    wish {set type "Tcl"}
                    tlcs {set type "Tcl"}
                }
            }
        }
        
        if {$type != ""} {
            ${type}::apply_syntax $textwidget
            ${type}::parse_text $textwidget
        }
    }
}
