#!/usr/bin/env ruby

#
# IdaRub
#
# Word up.
#

require 'socket'
require 'thread'

module IdaRub

	def self.new_client(host = '127.0.0.1', port = 1234)
		RemoteRub::ClientTcpSession.new(TCPSocket.new(host, port.to_i))
	end

	def self.auto_client
		hostport = ARGV.empty? ? [ ] : ARGV.shift.split(':')
		ida = (sess = new_client(*hostport)).front
		return ida, sess
	end

	def self.remote?
		true
	end
	def self.local?
		!remote?
	end

	module RemoteRub

		#
		# This class represents an object on the server side.
		#
		# We basically just have a token to retrieve the object back
		# on the server side.  So we can pass a RefObject as an
		# argument, and it will get converted back to the actual
		# server-side object.
		#
		# We can also call methods on RefObjects.  This is pretty much
		# the only way method invocation happens.  Remoted method calls
		# will be going through here...
		#
		class RefObject

			# remove functions that might conflict with remote ones
			undef_method :id, :type

			#
			# Custom marshaling, don't bother with passing session
			# around since it has no meaning on the other side...
			#
			def self._load(str)
				return RefObject.new(str.unpack('V')[0])
			end
			def _dump(depth)
				return [ ref_id ].pack('V')
			end

			attr_accessor :ref_id, :session

			def initialize(_id = nil, _sess = nil)
				self.ref_id = _id
			end

			#
			# Would be nice to do this a better way, ideas?
			#
			def method_missing(meth, *args)
				# redirect remote_xyz to xyz, convenient for
				# calling methods that exist on the RefObjet,
				# ie obj.remote_object_id
				if meth.to_s =~ /^remote_(.*)/
					meth = $1.to_sym
				end
				send_remote(meth, *args)
			end

			def send_remote(meth, *args)
				session.send_remote(self, meth, *args)
			end

			def lock(&blk)
				session.lock(&blk)
			end

			def unlock
				session.unlock
			end
		end

		#
		# Translates all of the stuff to handle unmarshalable objects,
		# represented as references of objects saved on the client side.
		# Stored in a table will prevent garbage collection and allow
		# objects to be mapped back.
		#
		class Transformer

			OK_KLASSES = [
			  Numeric,
			  String,
			  FalseClass,
			  TrueClass,
			  NilClass
			]

			#
			# Transforms
			#
			def transform(obj)
				return obj.class != Array ?
				  transform_element(obj) :
				  ( obj.map { |x| transform_element(x) } )
			end

			def transform_element(x)
				OK_KLASSES.each do |ok|
					return x if x.class <= ok
				end

				#
				# A ref object..
				#
				if x.class <= RefObject
					return transform_from_ref(x)
				end

				#
				# An object we to make a ref object
				#
				return transform_to_ref(x)
			end

			def transform_from_ref(x)
				raise "from_ref"
			end

			def transform_to_ref(x)
				raise "to_ref"
			end
		end

		#
		# Client arguments/return value transformer
		#
		# We shouldn't need to do anything to the method arguments
		#
		# We will need to add the sessions into RefObjects in return values
		#
		class ClientTransformer < Transformer

			attr_accessor :session

			def initialize(_sess = nil)
				self.session = _sess
			end

			#
			# We will keep the RefObjects, we will just
			# add in the session that they're from...
			#
			# So the client can call methods on it, you know..
			#
			def transform_from_ref(x)
				x.session = session
				return x
			end
		end

		#
		# Client Session Object
		#
		# This provides the transport to talk to the remote host,
		# and methods for communicating with it, etc.  This represents
		# one connection to the server.  Multiple session objects can
		# exist at the same time, and can be connected to the same or
		# different servers.  Of course a RefObject is only associated
		# with one session.
		#
		class ClientSession

			attr_accessor :transformer, :front, :comm_mutex, :lock_ctr, :lock_mutex

			def initialize
				self.transformer = ClientTransformer.new(self)
				self.comm_mutex  = Mutex.new
				self.lock_mutex  = Mutex.new
				self.lock_ctr    = 0

				# recv the front object
				self.front = transformer.transform(load_remote)
			end

			def lock(&blk)
				_lock
				if blk
					blk.call
					unlock
				end
			end

			def _lock
				# sloppy mutex usage...
				lock_mutex.synchronize do
					if lock_ctr == 0
						if !send_remote(nil, :lock)
							raise "Failed to lock server"
						end
					end
					self.lock_ctr = lock_ctr + 1
				end
			end

			def unlock
				lock_mutex.synchronize do
					self.lock_ctr = lock_ctr - 1
					if lock_ctr == 0
						if send_remote(nil, :unlock)
							raise "Failed to unlock server"
						end
					end
				end
			end

			def transform_return(ret)
				transformer.transform(ret)
			end

			def send_remote(obj, meth, *args)

				res = nil
				ret = nil

				comm_mutex.synchronize do
					dump_remote( [ obj, meth, args ] )
					res, ret = load_remote
				end

				# call failed, ret is an exception
				if !res
					raise ret
				end

				return transform_return(ret)
			end

		end
				

		#
		# TCP Transport...
		#
		module TcpSession

			attr_accessor :sock

			def initialize(_sock, *args)
				self.sock = _sock
				super(*args)
			end

			def dump_remote(obj)
				Marshal.dump(obj, sock)
			end

			def load_remote
				Marshal.load(sock)
			end

			def close
				sock.close
			end
		end

		class ClientTcpSession < ClientSession
			include TcpSession
		end

	end
end
