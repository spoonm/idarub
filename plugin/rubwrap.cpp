#include "idarub.h"

#define idarub_warning

static bool ruby_loaded = false;

EXTERN_C IMAGE_DOS_HEADER __ImageBase;

// cache these handles instead of looking them up for every call
static VALUE module_idaint         = NULL;
static VALUE intern_run_file       = NULL;
static VALUE intern_plugin_init    = NULL;
static VALUE intern_plugin_destroy = NULL;
static VALUE intern_plugin_accept  = NULL;
static VALUE intern_plugin_recv    = NULL;
static VALUE intern_plugin_close   = NULL;

//
// translate a .fileno into the real socket handle
//
static VALUE translate_fileno(VALUE self, VALUE fileno)
{
	return INT2FIX(rb_w32_get_osfhandle(FIX2INT(fileno)));
}

//
// load up internal ruby code...
//
static void init_idaint()
{

	rb_eval_string(
// stay street...
#include "inlined_ruby.cstr"
	);

	module_idaint         = rb_define_module("IdaInt");
	intern_run_file       = rb_intern("run_file");
	intern_plugin_init    = rb_intern("plugin_init");
	intern_plugin_destroy = rb_intern("plugin_destroy");
	intern_plugin_accept  = rb_intern("plugin_accept");
	intern_plugin_recv    = rb_intern("plugin_recv");
	intern_plugin_close   = rb_intern("plugin_close");

	rb_define_module_function(
		module_idaint,
		"plugin_translate_fileno",
		(VALUE (*)(...))translate_fileno,
		1
	);
}

//
// Initialize and load all the ruby code, swig bindings, etc
//
void init_ruby()
{
	if(!ruby_loaded) {
		//
		// So, artifically inflate our reference count so that our dll
		// won't be unloaded.  I'm doing this so I can keep track of
		// whether ruby is loaded or not. I would use PLUGIN_FIX, but
		// then it won't call my term routine...
		//
		char dllname[1024];
		GetModuleFileName((HMODULE)&__ImageBase, dllname, sizeof(dllname));
		LoadLibrary(dllname);

		// Initialize ruby interpreter

		ruby_init();
		ruby_script("idarub");
		ruby_init_loadpath();

		// load all of the internal ruby code
		init_idaint();
		// load the swig'd modules
		Init_Sdk();

		msg(LPREFIX "loaded ruby interpreter: %s\n", ruby_version);

		ruby_loaded = true;
	}
}

// NULL to run last file...
void run_ruby_file(const char * filename) {
	rb_funcall(
		module_idaint,
		intern_run_file,
		1,
		filename ? rb_str_new2(filename) : Qnil
	);
}

bool start_rub_server(const char * host, int eport, int sport)
{
	VALUE res;
	SOCKET serv_fd = 0;

	// returns the server listening socket
	res = rb_funcall(
	  module_idaint,
	  intern_plugin_init,
	  3,
	  rb_str_new2(host),
	  INT2FIX(eport),
	  INT2FIX(sport)
	);

	if (res == Qnil) {
		return false;
	}

	serv_fd = (SOCKET)FIX2INT(res);

	if (!serv_fd) {
		warning(LPREFIX "invalid server fd\n");
		return false;
	}

	if (WSAAsyncSelect(serv_fd, cwindow, WM_NETEVENT, FD_ACCEPT) == SOCKET_ERROR) {
		warning(
			LPREFIX "failed to async select on server socket %d, %lu\n",
			serv_fd,
			WSAGetLastError()
		);
		return false;
	}

	return true;
}

void stop_rub_server()
{
	// close out all sockets and such
	rb_funcall(
		module_idaint,
		intern_plugin_destroy,
		0
	);
}

void accept_client()
{
	SOCKET cli_fd = 0;

	// returns the client socket after an accept
	cli_fd = (SOCKET)FIX2INT(rb_funcall(
	  module_idaint,
	  intern_plugin_accept,
	  0
	));

	msg(LPREFIX "accepted client %d\n", cli_fd);

	if (WSAAsyncSelect(cli_fd, cwindow, WM_NETEVENT, FD_READ|FD_CLOSE) == SOCKET_ERROR)
		idarub_warning(LPREFIX "failed to async select on client socket %d, %lu\n", 
			cli_fd, WSAGetLastError());
}

void process_client(SOCKET sock)
{
	rb_funcall(
	  module_idaint,
	  intern_plugin_recv,
	  1,
	  INT2FIX(sock) // skape says sock should be ok at 31 bits
	);

	if (WSAAsyncSelect(sock, cwindow, WM_NETEVENT, FD_READ|FD_CLOSE) == SOCKET_ERROR)
		idarub_warning(LPREFIX "failed to async select client %d, %lu\n", 
			sock, WSAGetLastError());

}

void close_client(SOCKET sock)
{
	rb_funcall(
	  module_idaint,
	  intern_plugin_close,
	  1,
	  INT2FIX(sock) // skape says sock should be ok at 31 bits
	);

	msg(LPREFIX "close client %d\n", sock);
}
