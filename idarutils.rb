
#
# Return a list of area_t objects from an ea...
#
def function_chunks(ida, ea)
	entry = ida.get_func(ea)

	if !entry
		raise "No function at #{ea}"
	end
	if !ida.is_func_entry(entry)
		raise "Not an entry chunk at #{ea} #{entry.startEA}"
	end

	areas = [ entry ]
	it = ida.Func_tail_iterator_t.new(entry)

	ok = it.first
	while ok
		areas << it.chunk
		ok = it.next
	end

	return areas
end

