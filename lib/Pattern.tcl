
# Include guard
if {[info exists ::sourced_Pattern]} {
    return 0
}
set ::sourced_Pattern yes

snit::type Pattern {
    variable name 
    variable pattern

}
