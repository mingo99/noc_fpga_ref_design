#!/usr/bin/tclsh

# prints results for test_sequence_2, for different number of steps

array unset bram
set sum 0
set v 1
set addr 0
for {set i 0} {$i < 32} {incr i} {
    for {set j 0} {$j < 8} {incr j} {
        if {$v > 127} {
            set v [expr $v - 256]
        }
        set bram($addr) $v
        incr v
        incr addr
    }
}
set v 0
set addr 0
for {set i 0} {$i < 20} {incr i} {
    for {set j 0} {$j < 8} {incr j} {
        if {$v > 127} {
            set v [expr $v - 256]
        }
        if {$j == 0} {
            set s "$sum + $v * $bram($addr)"
        } elseif {$j == 7} {
            append s " + ... + $v * $bram($addr)"
        }
        set sum [expr $sum + $v * $bram($addr)]
        incr v
        incr addr
    }
    puts "          $s ="
    puts "[format %8d [expr $i+1]]: $sum"
}
