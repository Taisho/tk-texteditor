namespace eval Tcl {

    proc parse_text { widget lang } {
        set text [$widget get 0.1 end];
        set SyntaxRules [dict create]
        set SyntaxRules [parse text]

        dict for {index object} $SyntaxRules {
             set start [dict get $object start]
             set tag [dict get $object tag]
             set end [dict get $object end]

            $widget tag add $tag $start $end
        }
        # return SyntaxRules
    }

    ## in this method we will
    ## duplicate some logic with
    ## parse_dbl_quotes, but that is
    ## necessery. 
    #
    ## This method already recieves a copy of the
    ## text being parsed, so we can throw away
    ## parts of it at will
    proc parse { t } {
        upvar $t text
        set Tags [dict create]
        # possible values are plain,
        # DblQuote and Variable
        set Now plain

        for {set i 0; set c 0; set l 1; set tnum 0} { $i < [string length "$text"]} { incr i } {

            set char [string index "$text" $i]

            if {[string compare [string index "$text" $i] "\n"] == 0} {
                incr l
                set c 0
            }

            if {[string compare $Now "plain"] == 0} {

                if { [string compare [string index $text $i] "\""] == 0 } {
                ##
                ## Opening double quote encountered
                ##
                    set text [string range "$text" $i end]
                    puts "set tags parse_dbl_quotes \"$text\""
                    set tags [parse_dbl_quotes text c l]

                    ## The last tag's end property is of our
                    ## interest as we will use it to adjust
                    ## $charIndex ($c) for current line
                    #set c 0
                    ##TODO add charIndex from 'end' property from the
                    ## last tag returned by parse_dbl_quotes to $c


                    ##TODO $l (line index) will need to be adjusted
                    ## based on what's "consumed" by the parse_dbl_quotes
                    ## procedure

                    ## we need to reset the $i index, as the $text
                    ## variable would have lost a portion of its beginning
                    #set i 0 

                    ## We need to alter the tags returned by
                    ## parse_dbl_quotes, as their opening
                    ## and closing "addresses" (indexes in Tk
                    ## terminology) is local to the substring
                    ## being parsed. *This* procedures keeps
                    ## track of indexes from the beginning of
                    ## the text that was parsed.

                    #puts "adjust_tags_indexes tags $c $l"
                    #adjust_tags_indexes tags $c $l
                    #puts "(outside: adjust_tags_indexes) $tags"

                    concat_dicts Tags tags
                }
            }
            incr c
         }

         return $Tags
    }

    proc concat_dicts { D1 D2 } {
        upvar $D1 dict1;
        upvar $D2 dict2;
        set keys [dict keys $dict1]
        set index [llength keys]
        set d2Length [llength [dict keys $dict2]]

        for {set i $index; set y 0} {$y < $d2Length} {incr i; incr y} {
            dict set dict1 $i [dict get $dict2 $y]
    }
    }

    proc adjust_tags_indexes { T charOffset lineOffset} {
        upvar $T Tags
        ##
        ## We are going to alter only the $charIndex
        ## for the first line
        ##

        if {[dict exists $Tags 0]} {
            #dict set Tags 
            dict for {key tag} $Tags {

                #puts "key: $key, tag: $tag"

                #if {$key == 0} {
                #    continue
                #}
                ## we are going to adjust only line numbers
                ## for all lines except the first one.

                regexp {^([^.]+).([^.]+)} "[dict get $tag start]" -> lineIndex charIndex
                set lineIndex [expr $lineIndex + $lineOffset]
                dict set Tags $key start "$lineIndex.$charIndex"
                puts "dict set Tags $key start \"$lineIndex.$charIndex\""

                regexp {^([^.]+).([^.]+)} "[dict get $tag end]" -> lineIndex charIndex
                set lineIndex [expr $lineIndex + $lineOffset]
                dict set Tags $key end "$lineIndex.$charIndex"
                puts "dict set Tags $key end \"$lineIndex.$charIndex\""
            }

            set firstLine [dict get $Tags 0]

            ## start
            regexp {^([^.]+).([^.]+)} "[dict get $firstLine start]" -> lineIndex charIndex
            set charIndex [expr $charIndex + $charOffset]
            set startLineNum $lineIndex
            puts "dict set Tags 0 start \"$lineIndex.$charIndex\""
            dict set Tags 0 start "$lineIndex.$charIndex"

            ## end
            regexp {^([^.]+).([^.]+)} "[dict get $firstLine end]" -> lineIndex charIndex 
            if { $lineIndex == $startLineNum } {
                set charIndex [expr $charIndex + $charOffset]
                puts "dict set Tags 0 end \"$lineIndex.$charIndex\""
                dict set Tags 0 end "$lineIndex.$charIndex"
            }

            puts "(inside: adjust_tags_indexes) $Tags"
        }
    }

    # This procedure is used to overcome a limitation of Tcl - namely that references
    # to Dictionary elements don't exist. However, Dictionary references are still
    # available, because they are hold in regular variables and the latter can be
    # referenced withing another proc using the 'upvar' command.
    #
    # This procedure modifies the given dictionary in place. That is - no value is
    # returned. For this to work the dictionary should not be passed in its whole,
    # rather its variable name
    #
    # Functionality: Begings looking for the given tag name in the given dictionary
    #
    # Parameters:
    # * dict - name of the dictionary variable whose contents will be used
    # * Tag - name of the tag to be looked for
    # * prop - Dictionary's key
    # * value - The value that will be used as a new value
    #
    proc setLastTag {dict Tag prop value} {
        upvar $dict Dict

        set reversedKeys [lreverse [dict keys $Dict]]
        set length [llength reversedKeys]
        #set returnTag 

        for {set i 0} {$i < $length} {incr i} {
            if {[string compare [dict get $Dict [lindex $reversedKeys $i] tag] $Tag] == 0} {
                dict set Dict [lindex $reversedKeys $i] $prop $value
            }
        }
    }

    ## this procedure expects a text [whose begining at
    ## least is] enclosed in double quotes. The opening double
    ## quote must be present
    
    proc parse_dbl_quotes { t ci li} {
        upvar $t text
        upvar $ci chrIndex
        upvar $li lnIndex

        set Tags [dict create]
        # possible values are plain
        # and variable
        set Now Plain

        # TODO scan for setting variables with "set " and apply tags for variable' encounters
        for {set i 0; set c $chrIndex; set l $lnIndex; set vnum 0} { $i < [string length "$text"]} { incr i; set chrIndex $c; set lnIndex $l} {

            if { [string compare [string index "$text" $i] {\$}] == 0 } {
                dict set Tags $vnum [dict create start "$l.$c" tag Variable]
                set Now Variable
                incr vnum
            }
            if { [string compare "$Now" Plain] == 0} {
                if { [string compare [string index "$text" $i] "\""] == 0 } {
                    dict set Tags $vnum [dict create start "$l.$c" tag DoubleQuotes]
                    set Now DoubleQuotes
                    incr vnum
                }
            } else {
                ## *If the character we are at is a double quote we must terminate
                if {[regexp "\"" [string index "$text" $i]] == 1} {
                    set Now Plain
                    setLastTag Tags DoubleQuotes end "$l.[expr $c+1]"

                }

                ## *If the character we are at is non-alphanumeric consider variable name to have been collected
                if {[string compare "$Now" Variable] == 0 && [regexp {\W} string index "$text" $i] == 1} {
                    set Now Plain
                    set Tag [dict get $Tags $vnum]
                    dict set Tag end "$l.$c"
                }
            }
            incr c;

            ## encountering a new line
            ## character. Reflect that
            ## in the program
            if {[regexp "\n" [string index $text $i]] == 1} {
                #puts "new line"
                incr l;
                set c 0;
            }
        }

        ## here we are altering the
        ## variable passed to us by the
        ## caller. The caller must
        ## take this into account.
        ## A conventional for loop there
        ## might not be appropriate
        ## as it's making a copy of
        ## the iterated dictionary.
        set text [string range "$text" $i end]

        return $Tags
    }

    proc apply_syntax_tk { textwidget lang } {
        # //
        # // NOTE when passing accross Tk widget to
        # // a procedures, don't upvar it, as Tk
        # // widget identifiers are not variables
        # // (rather procedures)
        # //
        $textwidget tag configure comment -foreground #ececec
        $textwidget tag configure variable -foreground red
        $textwidget tag configure word_proc -foreground red
        $textwidget tag configure DoubleQuotes -foreground red
    }
}
