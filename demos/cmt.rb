#!/usr/bin/env ruby

#
# REcon 2006 - Comment porter demo
#
# Will port ithe comments of the current function (chunk) from two .idb's
# of the same executable.  Not very glamorous, but it's just meant to show
# how you could potentially use IdaRub for collaboration.
#
# Ex: ruby ./cmt.rb 127.0.0.1:1234 127.0.0.1:1235
#

$:.unshift('..')
require 'idarub'

ida1, = IdaRub.auto_client
ida2, = IdaRub.auto_client

f = ida1.get_func(ida1.get_screen_ea)

# sloppy since I ignore instruction boundaries, but well, it works...
(f.startEA .. f.endEA).each { |ea|
	if str = ida1.get_cmt(ea, true)
		ida2.set_cmt(ea, str, true)
		puts "0x%08x %s" % [ ea, str ]
	end
}
