namespace eval Languages {

    proc parse_text { widget } {
        set text [$widget get 0.1 end];
        set SyntaxRules [dict create]
        set SyntaxRules [parse text]
        #set SyntaxRules "0 {start 3.0 end 3.2 tag Hashbang}"

        #puts "\n\n\n"
        #puts " (parse_text)"
        #puts $SyntaxRules

        dict for {index object} $SyntaxRules {
             set start [dict get $object start]
             set tag [dict get $object tag]

             set end ""
             if {[dict exists $object end]} {
                 set end [dict get $object end]
             }

            if {$end == ""} {
                set end end
            }
            $widget tag add $tag $start $end
        }
        # return SyntaxRules
    }

    proc home {textWidget} {
        set text [home-source-code]
        $textWidget insert end $text 
    }


    proc home-source-code {} {
        return {
            
            [Show me Dictionary][dictionary]

            [Start a Quiz][quiz]

            [dictionary]: <kreut://languages/dictionary>
            [quiz]: <kreut://languages/quiz>
        }
    }

    proc apply_syntax { textwidget } {

        # //
        # // NOTE when passing accross Tk widget to
        # // a procedures, don't upvar it, as Tk
        # // widget identifiers are not variables
        # // (rather procedures)
        # //
        $textwidget configure -font regular
        $textwidget tag configure comment -foreground #ececec
        $textwidget tag configure variable -foreground red
        $textwidget tag configure word_proc -foreground red
        $textwidget tag configure DoubleQuotes -foreground red
        $textwidget tag configure Hashbang -background #99D535 -foreground white -font bold
        $textwidget tag configure Keyword -foreground #FB2710 -font bold
        $textwidget tag configure Variable -foreground #FB2710 -font bold
    }
}
