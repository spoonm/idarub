#!/usr/bin/env ruby

def dump(filename)
	File.open(filename, "r") do |file|
		file.each_line do |line|
			puts line.inspect
		end
	end
end

dump("../idarub.rb")
dump("../idarutils.rb")
dump("idarub_server.rb")
dump("idaint.rb")
