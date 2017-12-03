// An array of pointers

#ifndef PARRAY_HC
#define PARRAY_HC

#include "Array.HC"
#include "Exception.HC"
#include "GCCommon.HC"
#include "Util.HC"

extern CHAR *mal_alloc(INT size);

// NOTE: since PArrays are garbage-collected, only other garbage-collected
// values should be stored in them (Env, PArray, Malval, String).

class PArray
{
  BOOL _reachable; // for GC
  CHAR _gc_tag;
  Array *_arr;
};

CHAR *PArrayGet(PArray *pa, INT i)
{
  NullCheck(pa, "parray");
  // If we don't use INT* here, the value gets truncated to CHAR
  return *(ArrayGet(pa->_arr, i)(CHAR**))(INT*);
}

extern VOID GC_mark_object(GCCommon *o);
VOID PArrayGCMark(PArray *p)
{
  /* PArray *p = pa(PArray*); */
  if (!p->_reachable) {
    p->_reachable = TRUE;
    INT i;
    for (i = 0; i < ArraySize(p->_arr); ++i) {
      GC_mark_object(PArrayGet(p, i));
    }
  }
}

PArray *PArrayEmpty()
{
  PArray *pa = mal_alloc(sizeof(PArray));
  pa->_arr = ArrayMk(sizeof(CHAR*), 64);
  pa->_gc_tag = GC_PARRAY;
  return pa;
}

// DON'T USE THIS -- only for the GC
PArray *_PArrayEmpty_GC()
{
  PArray *pa = MAlloc(sizeof(PArray));
  pa->_arr = ArrayMk(sizeof(CHAR*), 64);
  pa->_gc_tag = GC_PARRAY;
  return pa;
}

PArray *PArrayMk(Array *a)
{
  PArray *pa = mal_alloc(sizeof(PArray));
  pa->_arr = a;
  pa->_gc_tag = GC_PARRAY;
  return pa;
}

// The actual elements will be deleted by the GC.
VOID PArrayDelete(PArray *pa)
{
  NullCheck(pa, "parray");
  ArrayDelete(pa->_arr);
  Free(pa);
}

// Not really a deep copy since only the pointers are copied.
PArray *PArrayCopy(PArray *pa)
{
  NullCheck(pa, "parray");
  PArray *p = PArrayMk(ArrayCopy(pa->_arr));
  return p;
}

INT PArraySize(PArray *pa)
{
  NullCheck(pa, "parray");
  return ArraySize(pa->_arr);
}

VOID PArraySet(PArray *pa, INT i, CHAR *p)
{
  NullCheck(pa, "parray");
  ArraySet(pa->_arr, i, &p);
}

VOID PArrayPush(PArray *pa, CHAR *p)
{
  NullCheck(pa, "parray");
  ArrayPush(pa->_arr, &p);
}

VOID PArrayPop(PArray *pa)
{
  NullCheck(pa, "parray");
  ArrayPop(pa->_arr);
}

// Erase range from index i to index j
VOID PArrayErase(PArray *pa, INT i, INT j)
{
  NullCheck(pa, "parray");
  ArrayErase(pa->_arr, i, j);
}

INT PArrayRemove(PArray *pa, CHAR *p)
{
  NullCheck(pa, "parray");
  INT i;
  for (i = 0; i < PArraySize(pa); ++i) {
    if (p == PArrayGet(pa, i)) {
      PArrayErase(p, i, i+1);
      return TRUE;
    }
  }
  return FALSE;
}

CHAR *PArrayBack(PArray *pa)
{
  NullCheck(pa, "parray");
  return *(ArrayBack(pa->_arr)(CHAR**))(INT*);
}

PArray *PArrayFront(PArray *pa)
{
  NullCheck(pa, "parray");
  return *(ArrayFront(pa->_arr)(CHAR**))(INT*);
}

// Return the tail of a PArray (creates new PArray)
PArray *PArrayTail(PArray *pa)
{
  NullCheck(pa, "parray");
  if (PArraySize(pa) < 1) {
    throws("Argument to 'PArrayTail' must have length >= 1");
  }
  PArray *p = PArrayCopy(pa);
  PArrayErase(p, 0, 1);
  return p;
}

// this doesn't work?
/* VOID PArrayConcat(PArray *p1, PArray *p2) */
/* { */
/*   NullCheck(p1, "parray 1"); */
/*   NullCheck(p2, "parray 2"); */
/*   ArrayConcat(p1->_arr, p2->_arr); */
/* } */

VOID PArrayConcat(PArray *p1, PArray *p2)
{
  NullCheck(p1, "parray 1");
  NullCheck(p2, "parray 2");
  INT i;
  for (i = 0; i < PArraySize(p2); ++i) {
    PArrayPush(p1, PArrayGet(p2, i));
  }
}

VOID PArrayInsert(PArray *pa, INT i, CHAR *p)
{
  NullCheck(pa, "parray");
  ArrayInsert(pa->_arr, i, &p(CHAR*));
}

BOOL PArrayExists(PArray *pa, CHAR *p)
{
  NullCheck(pa, "parray");
  return ArrayExists(pa->_arr, &p(CHAR*));
}

VOID PArrayClear(PArray *pa)
{
  NullCheck(pa, "parray"); 
  ArrayClear(pa->_arr);
}

#endif
