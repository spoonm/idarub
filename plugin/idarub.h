#ifndef _IDARUB_IDARUB_H
#define _IDARUB_IDARUB_H

#include <windows.h>
#include <ida.hpp>
#include <idp.hpp>
#include <dbg.hpp>
#include <loader.hpp>
#include <kernwin.hpp>
#include <bytes.hpp>
#include <name.hpp>
#include <ua.hpp>

#include "rubwrap.h"

#define LPREFIX "IdaRub: "
#define WM_NETEVENT WM_USER + 1

extern HWND cwindow;

// ghetto

extern "C" {
	extern void Init_Sdk(void);
}

#endif
