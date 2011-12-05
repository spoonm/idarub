%include "typemaps.i"

/*
    Typemap for buf/bufsize combo where we just want to output something
    but we supply the buffer.  Will just allocate 1k ( quite sloppy :-\ ).

    Ignore the boolean/size output and just return the buffer or nil...

    Ex: get_cmt
*/
%typemap(in,numinputs=0) (char *buf, size_t bufsize) {
	char tempbuf[1024];
	tempbuf[0] = 0;
	$1 = tempbuf;
	$2 = sizeof(tempbuf);
}
%typemap(argout) (char *buf, size_t bufsize) {
	// ghetto, but result > 0 should work for both boolean
	// returns where it will be true, and for ssize_t returns
	// where is will be 0 or -1 or whatnot...
	// using result directly is even ghettoer, should use $result
	// but thats already converted to a ruby type...
	$result = (int)result > 0 ? rb_str_new2($1) : Qnil;
}

/*
    Typemap for buf/size, where we want to read a certain amount of data (size)
    and we need this buffer allocated.  Will allocate size bytes, and ret a str

    Ignore the boolean/size output and just return the buffer or nil...

    Ex: get_many_bytes
*/
%typemap(in) (void *buf, ssize_t size) {
	Check_Type($input, T_FIXNUM);
	$2 = FIX2INT($input);
	$1 = malloc($2);
}
%typemap(argout) (void *buf, ssize_t size) {
	// again ghettoness of access result directly and casting to an int
	$result = (int)result > 0 ? rb_str_new((char *)$1, $2) : Qnil;

	free($1);
}

/*
    Typemap for format string functions, just pass it a "%s", expected to do
    any formatting on the client side.

    Ex: msg
*/
%typemap(in) (const char *format, ...) {
	Check_Type($input, T_STRING);
	$1 = "%s";
	$2 = RSTRING($input)->ptr;
};

/*
    Typemap for mapping output arguments for ea_t, sel_t, etc

    Ex: read_selection, getn_selector
*/
%apply ulong *OUTPUT { sel_t * };
%apply ulong *OUTPUT { ea_t * };

// usually comes from llong.hpp, but we don't need the header for
// anything besides these definitions...
%apply long long { longlong }
%apply unsigned long long { ulonglong }
