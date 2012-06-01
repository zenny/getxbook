#!/usr/bin/tclsh
# See COPYING file for copyright and license details.
package require Tk

set cmds {{getgbook "Google Book ID" "Google\nBook Preview" \
           "http*://books.google.*/*" {[&?]id=([^&]*)}} \
          {getabook "ISBN 10" "Amazon Look\nInside The Book" \
           "http*://*amazon*/*" {/([0-9]{10})/}} \
          {getbnbook "ISBN 13" "Barnes & Noble\nBook Viewer" \
           "http*://www.barnesandnoble.com/*" ""}}
set cmdselected 0
set dling 0
set manual 0

set env(PATH) "[file dirname $::argv0]:$env(PATH)"
set iconpath "[file dirname $::argv0]/icons"

proc updateStatus {chan} {
	global dling
	if {![eof $chan]} {
		set a [gets $chan]
		if { $a != "" } { .st configure -text $a }
	} else {
		if { ! [catch {close $chan}] } {
			.st configure -text "[.input.id get] Done"
		}
		.dl configure -state normal -text "Download"
		set dling 0
	}
}

proc go {} {
	global dling cmdselected cmds
	if { [.input.id get] == "" } { return }
	set cmd "[lindex [lindex $cmds $cmdselected] 0] [.input.id get]"
	set dling 1
	.dl configure -state disabled -text "Downloading"
	.st configure -text ""
	set out [open "|$cmd 2>@1" "r"]
	fileevent $out readable [list updateStatus $out]
}

proc parseurl {url} {
	global cmds
	set newid ""
	set i 0
	foreach b $cmds {
		if { [string match [lindex $b 3] "$url"] } {
			selcmd $i
			set cmdregex [lindex $b 4]
			if {"$cmdregex" != "" && [regexp "$cmdregex" $url m sub]} {
				set newid "$sub"
			}
			.input.id delete 0 end
			.input.id insert 0 "$newid"
		}
		incr i
	}
}

proc watchsel {} {
	global dling manual

	if { !$dling && !$manual && \
	     ! [catch {set sel "[clipboard get -type UTF8_STRING]"}] } {
		parseurl "$sel"
	}

	after 500 watchsel
}

proc selcmd {sel} {
	global cmds cmdselected

	.cmdfr.$cmdselected configure -relief flat
	set cmdselected $sel
	.cmdfr.$cmdselected configure -relief solid

	.input.lab configure -text [lindex [lindex $cmds $sel] 1]
}

frame .input
label .input.lab
entry .input.id -width 14

frame .cmdfr
set i 0
foreach b $cmds {
	set cmdname [lindex $b 0]
	if { [catch {image create photo im$i -file "$iconpath/$cmdname.gif"}] } {
		image create photo im$i
	}
	button .cmdfr.$i -text [lindex $b 2] -image im$i \
	       -command "selcmd $i" -compound top -relief flat
	pack .cmdfr.$i -side left
	bind .cmdfr.$i <Key> {set manual 1}
	bind .cmdfr.$i <Button> {set manual 1}
	incr i
}
.cmdfr.$cmdselected invoke

button .dl -text "Download" -command go
label .st

pack .input.lab -side left
pack .input.id

pack .cmdfr .input .dl .st
bind . <Return> go

bind .input.id <Key> {set manual 1}
bind .input.id <Button> {set manual 1}
watchsel
