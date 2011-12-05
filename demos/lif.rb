#!/usr/bin/env ruby

#
# REcon 2006 - Lif demo
#
# Plays a Conway's Game of Life in the function comment of the current ea's
# function.
#

$:.unshift('..')
require 'gameoflif'
require 'idarub'

ida, = IdaRub.auto_client

func = ida.get_func(ida.get_screen_ea)

b = GameOfLif.new_random(10, 60)

300.times do
	ida.set_func_cmt(func, b.output, false)
	ida.refresh_idaview_anyway
	b.step
	sleep(0.05)
end
