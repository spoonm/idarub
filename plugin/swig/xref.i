%include "xref.hpp"

%inline %{
	VALUE ir_xrefs_to(ea_t ea, int flags = XREF_ALL) {
		xrefblk_t xb;
		bool ok;
		VALUE xrefs = rb_ary_new();

		for(ok = xb.first_to(ea, flags); ok; ok = xb.next_to()) {
			rb_ary_push(xrefs, INT2NUM(xb.from));
		}

		return xrefs;
	}
	VALUE ir_xrefs_from(ea_t ea, int flags = XREF_ALL) {
		xrefblk_t xb;
		bool ok;
		VALUE xrefs = rb_ary_new();

		for(ok = xb.first_from(ea, flags); ok; ok = xb.next_from()) {
			rb_ary_push(xrefs, INT2NUM(xb.to));
		}

		return xrefs;
	}
%}
