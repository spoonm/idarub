#!/usr/bin/env ruby

#
# REcon 2006 - Marquee demo
#
# Silly demo that just marquees a comment at the current ea.  You can run
# multiple of these at once for extra awesomeness.
#

$:.unshift('..')
require 'idarub'

def rotate(str)
	str[0,0]   = str[-1, 1]
	str[-1, 1] = ""
	return str
end

ida, = IdaRub.auto_client

str = "yoz!!!           "

ea = ida.get_screen_ea

200.times do |i|
	ida.set_cmt(ea, rotate(str), true);
	ida.refresh_idaview_anyway
	sleep(0.05)
end
