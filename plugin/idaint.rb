# hack attack
alias :old_require :require
def require(str)
	return false if str == 'idarub' || str == 'idarutils'
	return old_require(str)
end

def puts(*args)
	IdaInt::Sdk.puts(*args)
end
def print(*args)
	IdaInt::Sdk.print(*args)
end

module IdaInt
	module Sdk
		def self.method_missing(meth, *args)
			if args.empty? && meth.to_s.between?('A', 'Z')
				begin
					return const_get(meth.to_s)
				rescue NameError
				end
			end
			return super(meth, *args)
		end
		def self.puts(*args)
			args.each do |arg|
				msg(arg + "\n")
			end
		end
		def self.print(*args)
			args.each do |arg|
				msg(arg)
			end
		end
	end

	class <<self
		attr_accessor :server, :sess_table, :last_file
	end

	def self.dump_exception(exp)
		IdaInt::Sdk.warning(([exp.message] + exp.backtrace).join("\n"))
	end

	def self.plugin_init(hostname = '0.0.0.0', sport = 1234, eport = 1239)

		self.sess_table = { }

		ports = (sport .. eport).to_a
		begin
			self.server = TCPServer.new(hostname, ports[0])
			IdaInt::Sdk.puts("IdaRub: Server started on %s:%d" % [ hostname, ports[0] ])
			return plugin_translate_fileno(server.fileno)
		rescue
			ports.shift
			retry if !ports.empty?
			dump_exception($!)
			return nil
		end
	end

	def self.plugin_accept
		begin
			client = server.accept
			fileno = plugin_translate_fileno(client.fileno)
			sess_table[fileno] = IdaRub.new_server(client, IdaInt::Sdk)
			return fileno
		rescue
			# if exception here, client probably disconnected
			# right after connect, problem sending front to
			# the client, etc...
			# it's fine, maybe should put something in msg()...
			return nil
		end
	end

	def self.plugin_recv(fno)
		sess = sess_table[fno]

		begin
			sess.recv_remote
		rescue
			# maybe put something in msg()..
			return nil
		end
	end

	def self.plugin_close(sock)
		begin
			sess_table.delete(sock).close
		rescue
			# maybe put something in msg()..
			return nil
		end
	end

	def self.plugin_destroy
		sess_table.each_pair do |sock, sess|
			begin
				sess.close
			rescue
				# maybe put something in msg()..
			end
		end
		sess_table.clear
		server.close
	end

	def self.plugin_translate_fileno(fno)
		return fno
	end

	def self.run_file(filename = nil)
		filename ||= last_file
		self.last_file = filename
		old_inc = $:.dup
		begin
			start_time = Time.now
			IdaInt::Sdk.puts("IdaRub: Running %s" % filename.inspect)
			# add both the IDA plugins directory and the base
			# directory of the executing file to the search path
			$: << 'plugins/' << File.dirname(filename)

			load filename
			IdaInt::Sdk.puts("IdaRub: Finished successfully (%.4g secs)." % (Time.now - start_time))
		rescue Exception
			dump_exception($!)
		ensure
			$:.replace(old_inc)
		end
	end
end
