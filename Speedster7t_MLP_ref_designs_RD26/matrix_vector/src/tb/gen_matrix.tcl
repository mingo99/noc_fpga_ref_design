#!/usr/bin/tclsh

# Generate various matrices.
#
# Can call this file with a command as argument, e.g.,
#
#    gen_matrix.tcl matrix_diag 2
#
# or source this file in a script.
#
###############################################################################


# put v on diagonal, 0 elsewhere
proc matrix_diag {v {rows 256} {cols 256}} {
    puts ""
    puts "// **** value $v at diagonal: multiply vector by $v"
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            if {$c == $r} {
                puts -nonewline "[format %02x $v] "
            } else {
                puts -nonewline "00 "
            }
        }
        puts "\n"
    }
}


# put v on reverse diagonal, 0 elsewhere
proc matrix_rev_diag {v {rows 256} {cols 256}} {
    puts ""
    puts "// **** value $v at reverse diagonal: reverse vector and multiply by $v"
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            if {$c == 255 - $r} {
                puts -nonewline "[format %02x $v] "
            } else {
                puts -nonewline "00 "
            }
        }
        puts "\n"
    }
}


# matrix with random int8 values
proc matrix_rand {{rows 256} {cols 256} {seed ""}} {
    puts ""
    puts "// **** random int8 values"
    if {[string length $seed]} {
        puts "// seed = $seed"
        expr srand($seed)
    }
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            set v [expr round(255*rand())]
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            puts -nonewline "[format %02x $v] "
        }
        puts "\n"
    }
}


# set wide diagonal to do ((x-3) + x + (x+1) + (x+2)) * v
# with some variations at the edges
proc matrix_wide_diag {v {rows 256} {cols 256}} {
    puts ""
    puts "// **** wide diagonal, with entry $v at (r-3), r, (r+1), (r+2)"
    puts "//      effect: mult vector by 4*$v = [expr 4*$v]"
    set cols_mid [expr $cols / 2]
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        array unset map
        set map(0) 1
        # note: vector is 0..127, 0..127 (not 0..255) so must treat middle
        # in the same way as the edges
        set m [expr $r & ($cols_mid - 1)]
        if {0 <= $m - 3} {
            set map(-3) 1
        } else {
            set map(3) -1
            incr map(0) 2
        }
        if {$m + 2 < $cols_mid} {
            set map(2) 1
        } else {
            set map(-2) -1
            incr map(0) 2
        }
        if {$m + 1 < $cols_mid} {
            set map(1) 1
        } else {
            set map(-1) -1
            incr map(0) 2
        }
        for {set c 0} {$c < $cols} {incr c} {
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            set offset [expr $c - $r]
            if {[info exists map($offset)]} {
                set e [expr ($map($offset) * $v) & 0xFF]
                puts -nonewline "[format %02x $e] "
            } else {
                puts -nonewline "00 "
            }
        }
        puts "\n"
    }
}


# on diagonal, put v at odd entries, -v at even entries
proc matrix_diag_even_neg {v {rows 256} {cols 256}} {
    puts ""
    puts "// **** on diagonal, -$v for even entries, $v for odd entries"
    puts "//      effect: even entries * -$v, odd entries *v"
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            if {$c == $r} {
                if {$r & 0x1} {
                    puts -nonewline "[format %02x $v] "
                } else {
                    set e [expr -$v & 0xFF]
                    puts -nonewline "[format %02x $e] "
                }
            } else {
                puts -nonewline "00 "
            }
        }
        puts "\n"
    }
}


# put v on diagonal, 0 elsewhere, but shift diagonal one up
proc matrix_diag_shift_up {v {rows 256} {cols 256}} {
    puts ""
    puts "// **** value $v at diagonal, shifted one row up"
    puts "//      effect: vector shifted one up, mult by $v"
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            if {$c && ($c & 31) == 0} {
                puts ""
            }
            if {$c == $r+1} {
                puts -nonewline "[format %02x $v] "
            } else {
                puts -nonewline "00 "
            }
        }
        puts "\n"
    }
}


# even rows have entries 0, 1, 2, ...; odd rows count backwards
proc matrix_count {{rows 256} {cols 256}} {
    puts ""
    puts "// **** even rows count 0, 1, 2, ...; odd rows count backwards"
    set v 0
    for {set r 0} {$r < $rows} {incr r} {
        puts "// row $r"
        for {set c 0} {$c < $cols} {incr c} {
            puts -nonewline "[format %02x $v] "
            if {$c < $cols-1} {
                if {$r & 0x1} {
                    incr v -1
                } else {
                    incr v
                }
                set v [expr $v & 0xff]
            }
        }
        puts "\n"
    }
}


# If the first argument is a Tcl command (presumably one of the above procs),
# call that command with the other arguments
if {[llength $argv] && [string length [info commands [lindex $argv 0]]]} {
    {*}$argv
}

