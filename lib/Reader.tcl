# Reader is the core of parsing text. It understands a limited version
# of regular expressions, so rules can be specified and managed more easily.
#
# 
#

# Include guard
if {[info exists ::sourced_Reader]} {
    return 0
}
set ::sourced_Reader yes

snit::type Reader {
    property ruleStack
    property rules

    # @param Text
    # @return An array of tokens or tags
    typemethod read { text } {

    }

    snit::macro property {name initValue} {
        variable $name $initValue
        method get$name {} "return $name"
        method set$name {value} "set $name \$value"
    }
}
