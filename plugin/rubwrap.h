#ifndef _IDARUB_RUBWRAP_H
#define _IDARUB_RUBWRAP_H

extern "C" {
	#include "ruby.h"
	#include "version.h"
}

void init_ruby();
void run_ruby_file(const char *);
bool start_rub_server(const char * host, int eport, int sport);
void stop_rub_server();
void accept_client();
void process_client(SOCKET);
void close_client(SOCKET);

#endif
