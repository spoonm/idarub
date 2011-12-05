
// we do want to wrap qexit
%inline %{
        idaman void ida_export qexit(int code);
%}

/*
 * we want to do an import, just to load the types, but
 * we don't want to wrap any of the functions...
 */

%constant ea_t BADADDR = -1;
%import pro.h
