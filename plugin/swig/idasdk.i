%module "IdaInt::Sdk"

#define __LINUX__
#define _MSC_VER

%include "types.i"

%include "pro.i" // just imported for typedefs and stuff
%include "ida.i"
%include "kernwin.i"
%include "area.i"
%include "bytes.i"
%include "xref.i"
%include "funcs.i"
%include "name.i"
%include "gdl.i"
%include "search.i"
//%include "allins.i"
%include "auto.i"
%include "segment.i"
%include "lines.i"
%include "ua.i"
%include "sistack.i"
%include "moves.i"
%include "nalt.i"
%include "struct.i"
%include "srarea.i"
%include "strlist.i"
%include "queue.i"
%include "entry.i"
%include "frame.i"
%include "offset.i"
