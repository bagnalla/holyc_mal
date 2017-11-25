#ifndef GCTAGS_HC
#define GCTAGS_HC

#include "PrimitiveTypes.HC"

// GC tags
#define GC_ENV    0
#define GC_MALVAL 1
#define GC_PARRAY 2
#define GC_STRING 3
#define GC_LIST   4

class GCCommon
{
  BOOL _reachable;
  CHAR _gc_tag;
};

#endif
