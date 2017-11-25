#ifndef GC_HC
#define GC_HC

// Objects garbaged-collected:
// Env, Malval, PArray, String, List

// Objects not garbage-collected:
// Array, Hashmap, Symtab, SymtabEntry, HashmapEntry, Atom, Function,
// Closure

// This is because Arrays, Hashmaps, etc. are never used in isolation,
// but are used internally by PArray, String, Env, Malval, etc. So, we
// have functions for deleting these types that also delete their internal
// structures. This prevents the GC from doing extra work.

#include "Exception.HC"
#include "Env.HC"
#include "List.HC"
#include "PArray.HC"
#include "String.HC"
#include "Types.HC"

// Run the GC every 100000 allocations.
#define GC_PERIOD 100000

// Global array of all garbage-collected objects.
// _GC_objects is the active array. During the sweep phase we add
// reachable objects to the back array and then swap so it becomes the
// new front.
PArray *_GC_objects;
PArray *_GC_objects_back;

// Objects used by the interpreter that shouldn't be collected (but don't
// necessarily show up in any environments)
// Used in a LIFO manner during evaluation of terms, so we use a stack.
PArray *_GC_stack;

INT _GC_counter;

Env *_GC_root_env;

VOID init_GC()
{
  _GC_root_env = NULL;
  _GC_objects = _PArrayEmpty_GC;
  _GC_objects_back = _PArrayEmpty_GC;
  _GC_stack = _PArrayEmpty_GC;
  _GC_counter = 0;
}

// only use with types compatible with the GCCommon interface
CHAR *mal_alloc(INT size)
{
  CHAR *o = MAlloc(size);
  (o(GCCommon*))->_reachable = FALSE;
  PArrayPush(_GC_objects, o);
  _GC_counter++;
  return o;
}

VOID set_GC_root_env(Env *rootEnv)
{
  _GC_root_env = rootEnv;
}

extern VOID _print_GC_object(GCCommon *o);
VOID _print_parray(PArray *pa)
{
  INT i;
  for (i = 0; i < PArraySize(pa); ++i)  {
    _print_GC_object(PArrayGet(pa, i));
  }
}
VOID _print_list(List *l)
{
  "list\n"; // TODO
}

VOID _print_GC_object(GCCommon *o)
{
  switch (o->_gc_tag) {
  case GC_ENV:
    /* EnvPrint((Env*)o); */
    "env\n";
    break;
  case GC_MALVAL:
    StringPrintLn(PrintMalval(o(Malval*), TRUE, TRUE));
    break;
  case GC_PARRAY:
    _print_parray(o(PArray*));
    break;
  case GC_STRING:
    StringPrintLn(o(String*));
    break;
  case GC_LIST:
    _print_list(o(List*));
    break;
  default:
    throws("_GC_mark: unknown tag");
  }  
}

VOID GC_push(CHAR *o)
{
  PArrayPush(_GC_stack, o);
}

VOID GC_pop()
{
  PArrayPop(_GC_stack);
}

VOID GC_mark_object(GCCommon *o)
{
  switch (o->_gc_tag) {
  case GC_ENV:
    EnvGCMark(o);
    break;
  case GC_MALVAL:
    MalvalGCMark(o);
    break;
  case GC_PARRAY:
    PArrayGCMark(o);
    break;
  case GC_STRING:
    StringGCMark(o);
    break;
  case GC_LIST:
    ListGCMark(o);
    break;
  default:
    throws("_GC_mark: unknown tag");
  }
}

VOID print_GC_stack()
{
  _print_parray(_GC_stack);
}

VOID _GC_mark()
{
  if (!_GC_root_env) return;
  EnvGCMark(_GC_root_env);
  INT i;
  PArray *entries = _EnvEntries_GC(_GC_root_env);
  for (i = 0; i < PArraySize(_GC_stack); ++i) {
    GC_mark_object(PArrayGet(_GC_stack, i));
  }
  PArrayDelete(entries);
}

VOID _GC_sweep()
{
  INT i;
  for (i = 0; i < PArraySize(_GC_objects); ++i) {
    GCCommon *o = PArrayGet(_GC_objects, i);
    if (!o->_reachable) {
      switch (o->_gc_tag) {
      case GC_ENV:
	EnvDelete(o(Env*));
	break;
      case GC_MALVAL:
	MalvalDelete(o(Malval*));
	break;
      case GC_PARRAY:
	PArrayDelete(o(PArray*));
	break;
      case GC_STRING:
        StringDelete(o(String*));
	break;
      case GC_LIST:
	ListDelete(o(List*));
	break;
      default:
	throws("_GC_sweep: unknown tag");
      }
    }
    else {
      o->_reachable = FALSE; // reset reachable
      PArrayPush(_GC_objects_back, o);
    }
  }
  // Swap arrays and clear the new back array (old front). 
  PArray *temp = _GC_objects;
  _GC_objects = _GC_objects_back;
  _GC_objects_back = temp;
  PArrayClear(_GC_objects_back);
}

VOID run_GC()
{
  _GC_mark;
  _GC_sweep;
}

VOID print_GC_status()
{
  "_GC_objects size: %ld\n", PArraySize(_GC_objects);
  "_GC_stack size: %ld\n", PArraySize(_GC_stack);
}

VOID check_for_GC()
{
  if (_GC_counter > GC_PERIOD) {
    /* print_GC_status; */
    /* "running GC...\n"; */
    run_GC;
    /* print_GC_status; */
    _GC_counter = 0;
  }
}

VOID cleanup_GC()
{
  PArrayClear(_GC_stack);
  _GC_root_env = NULL;
  run_GC;
  PArrayDelete(_GC_objects);
  PArrayDelete(_GC_objects_back);
  PArrayDelete(_GC_stack);
}

INT GC_stack_size()
{
  return PArraySize(_GC_stack);
}

#endif
