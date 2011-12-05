#
# The IdaRub server side.  Normally you would need to require 'idarub.rb', since the server
# side uses some common components.  Since we are just inlining the code into the plugin
# just have to make sure to inline idarub.rb before idarub_server.rb...
#
module IdaRub

	def self.new_server(sock, front)
		RemoteRub::ServerTcpSession.new(sock, front)
	end

	def self.auto_client
		return IdaInt::Sdk, nil
	end

	def self.remote?
		false
	end

	module RemoteRub

		class ServerTransformer < Transformer

			attr_accessor :ref_table

			def initialize(_ref = { })
				self.ref_table = _ref
			end

			#
			# On the server end, take any RefObjects passed from the
			# client and map them back to the real objects...
			#
			def transform_from_ref(x)
				oid = x.ref_id
				if !ref_table.has_key?(oid)
					raise "Cannot find referenced object #{oid}"
				end
				return ref_table[oid]
			end

			#
			# On the server end, we want to take any return values
			# being passed back to the client, that may need to be
			# made into a reference...
			#
			def transform_to_ref(x)
				ref_table[x.object_id] = x
				return RefObject.new(x.object_id)
			end
		end

		class ServerSession
			attr_accessor :transformer, :front, :locked

			def initialize(_front)
				self.transformer = ServerTransformer.new
				self.front       = _front
				self.locked      = false

				# send the front object...
				dump_remote(transformer.transform(front))
			end

			def lock
				self.locked = true
			end

			def unlock
				self.locked = false
			end

			def transform_object(obj)
				transformer.transform(obj)
			end

			def transform_arguments(args)
				transformer.transform(args)
			end

			def transform_return(ret)
				transformer.transform(ret)
			end

			def recv_remote
				begin   # this begin loops while locked

					obj, meth, args = load_remote
					obj = transform_object(obj)

					#
					# Kind of a hack, but we have a side control channel
					# if obj is nil.  We set it to equal ourselves, so
					# that you can remotely call methods on this session
					# object.  I currently use this for locking...
					# and will be used for explicitly releasing ref objects...
					#
					obj = self if !obj

					# how deep should we transform for arguments?
					args = transform_arguments(args)
					ret = transform_return(obj.send(meth, *args))
					dump_remote( [ true, ret ] )
				# todo, rescue network/marshaling errors
				rescue
					# call failed, an exception, proxy it back
					dump_remote( [ false, $! ] )
				end until !locked
			end
		end

		class ServerTcpSession < ServerSession
			include TcpSession
		end
	end
end
