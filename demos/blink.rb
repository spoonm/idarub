#!/usr/bin/env ruby

#
# REcon 2006 - Blink demo
#
# Silly demo that just blinks a comment at the current ea.  You can run
# multiple of these at once for extra awesomeness.
#

$:.unshift('..')
require 'idarub'

ida, = IdaRub.auto_client

ea = ida.get_screen_ea

100.times do |i|
	ida.set_cmt(ea, i % 2 == 0 ? "blink!" : "", true);
	sleep(0.1)
end
