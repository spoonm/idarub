#!/usr/bin/env ruby

#
# REcon 2006 - GDB <-> IDA link demo
#
# Allows for the ability to link up GDB on any platform/architecture with IDA.
#
# Load the gdbinit file, and it adds commands like:
#   idasi     - Step instruction (si) and have IDA follow along
#   idafollow - Move IDA to the current GDB $pc
#   idabreak  - Breakpoint on the current IDA ea
#   idacmt    - Add an IDA comment and the current GDB $pc
#
# Note: Might need to switch the unpack('V') for non-intel architectures.
#       Should probably use 'L' since it will run on the same machine as GDB.
#

$:.unshift(File.join(File.dirname(__FILE__), '..'))
require 'idarub'

def pc
	File.open('/tmp/idarubgdb', 'r') { |f| f.read.unpack('V')[0] }
end
def out(data)
	File.open('/tmp/idarubgdb', 'w') { |f| f.write(data) }
end

host = ENV['IDARUB_HOST'] || '127.0.0.1'
port = ENV['IDARUB_PORT'] || 1234

sess = IdaRub.new_client(host, port)
ida  = sess.front

eval(ARGV[0])

ida.refresh_idaview_anyway
