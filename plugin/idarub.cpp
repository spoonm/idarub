#include "idarub.h"

#define WM_NETEVENT WM_USER + 1

EXTERN_C IMAGE_DOS_HEADER __ImageBase;

HWND cwindow = NULL;
WNDCLASS klass;

#define COPYZ "version 0.8 - (c) spoonm, wordz to skape"

//
// Handles the IDA window messages for the hidden control window.
//
static LRESULT CALLBACK control_window_proc(HWND wnd, UINT msg, 
		WPARAM wp, LPARAM lp)
{
	switch (msg)
	{
		case WM_NETEVENT:
			{
				switch (WSAGETSELECTEVENT(lp))
				{
					case FD_ACCEPT:
						accept_client();
						break;
					case FD_READ:
						process_client((SOCKET)wp);
						break;
					case FD_CLOSE:
						close_client((SOCKET)wp);
						break;
				}
			}
			break;
		default:
			return DefWindowProc(wnd, msg, wp, lp);
	}

	return 0;
}

//
// Creates a control window that is used to serialize access to the IDA database
// with the user interface thread such that the ruby thread can access SDK
// functions in a thread-safe manner.
//
static bool create_control_window()
{
	memset(&klass, 0, sizeof(klass));

	klass.hInstance     = (HINSTANCE)&__ImageBase;
	klass.lpfnWndProc   = control_window_proc;
	klass.lpszClassName = "idarub_ctl_window";
	klass.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
	klass.hCursor       = LoadCursor(NULL, IDC_ARROW);

	if(RegisterClass(&klass) == 0)
		return false;

	if (!(cwindow = CreateWindowEx(0, klass.lpszClassName, NULL, 
			WS_POPUP, 0, 0, 100, 100, NULL, NULL, klass.hInstance, 0)))
		return false;

	return true;
}

//
// Destroys the control communication window.
//
static void destroy_control_window()
{
	DestroyWindow(cwindow);
	cwindow = NULL;
	UnregisterClass(klass.lpszClassName, klass.hInstance);
}

//
// Start the server.
//   - create the control window
//   - start up the rub code...
//
static void start_server(const char * host, int eport, int sport)
{
	do
	{
		// Create the control window that will be used to serialize access to the
		// IDA SDK.
		if (!create_control_window())
		{
			warning(LPREFIX "failed to create control window, %lu.\n", 
				GetLastError());
			break;
		}

		if (!start_rub_server(host, eport, sport)) {
			destroy_control_window();
		}

	} while (0);
}

//
// Stop the server.
//   - Destroy the control window
//   - Stop the ruby server
//
static void idaapi stop_server(void)
{
	// better to kill interp or window first?
	destroy_control_window();
	stop_rub_server();
}

//
// Is the server current running?
//
static bool server_running()
{
	return cwindow != NULL;
}


//
//
// IDA Plugin Functions
//
//

static int idaapi init(void)
{
	const char * plugin_options = NULL;

	msg(LPREFIX "idarub loaded, " COPYZ "\n");

	// Support batch mode local file evaluation, via -OIdaRub:file:blah.rb
	// will eventually support a way to launch the server
	if(plugin_options = get_plugin_options("IdaRub")) {
		init_ruby();
		if(strncmp(plugin_options, "file:", 5) == 0)
			run_ruby_file(plugin_options + 5);
	}

	return PLUGIN_KEEP;
}

static void idaapi run(int arg)
{

	unsigned short loadfile = 0;
	unsigned int sport = 1234, eport = 1239;
	char ip[16] = "0.0.0.0";
	const char * filename;

	char foo[] =
		"STARTITEM 3\n" // shortcut to quickly load files, etc
		"IdaRub!\n"
		"Sucka Free!\n\n"
		"<Listen IP  :A:15:15::>\n"
		"<Start Port :D:5:5::>\n"
		"<End Port   :D:5:5::>\n"
		"<Start Server:R><Load File:R><Load Last File:R>>\n\n\n\n";
	
	// make sure ruby has been loaded...
	init_ruby();

	if(server_running()) {
		if(!AskUsingForm_c("IdaRub!\nStop Server\n\n"))
			return;

		stop_server();
		msg(LPREFIX "stopped the rub\n");
	}
	else {
		if(!AskUsingForm_c(foo, &ip, &sport, &eport, &loadfile))
			return;

		switch(loadfile) {
		case 2: // Load Last File
			run_ruby_file(NULL);
			break;
		case 1: // Load File
			filename = askfile_c(0, "*.rb", "Select Ruby script...");
			if(filename)
				run_ruby_file(filename);
			break;
		case 0: // Start Server
			start_server(ip, sport, eport);
			break;
		}
	}
}

static void idaapi term(void)
{
	if(server_running()) {
		stop_server();
	}
}

//
// Plugin registration stuff
//

static char plugin_short_name[] = "IdaRub";
static char plugin_comment[]    = "IdaRub";
static char plugin_hotkey[]     = "ALT-F7";
static char plugin_multiline[]  = "IdaRub";

plugin_t PLUGIN =
{
	IDP_INTERFACE_VERSION,
	0,
	init,
	term,
	run,
	plugin_comment,
	plugin_multiline,
	plugin_short_name,
	plugin_hotkey
};

