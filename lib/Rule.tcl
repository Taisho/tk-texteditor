
# Include guard
if {[info exists ::sourced_Rule]} {
    return 0
}
set ::sourced_Rule yes

snit::type Rule {
    property matchParenthesis
    property matchBrackets
    property matchBraces
    property EscapeSequence
    property pattern
    property prohibitNesting

    snit::macro property {name initValue} {
        variable $name $initValue
        method get$name {} "return $name"
        method set$name {value} "set $name \$value"
    }
}
