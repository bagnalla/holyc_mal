// A unified interface for lists and vectors.

#ifndef MAL_LIST_VECTOR_HC
#define MAL_LIST_VECTOR_HC

#include "MalList.HC"
#include "MalVector.HC"

BOOL MalIsListOrVector(Malval *m)
{
  return MalIsList(m) || MalIsVector(m);
}

Malval *MalHead(Malval *m)
{
  NullCheck(m, "malval");
  if (MalIsList(m)) return MalListHead(m);
  else return MalVectorHead(m);
}

Malval *MalTail(Malval *m)
{
  NullCheck(m, "malval");
  if (MalIsList(m)) return MalListTail(m);
  else return MalVectorTail(m);
}

Malval *MalNth(Malval *m, INT n)
{
  NullCheck(m, "malval");
  if (MalIsList(m)) return MalListNth(m, n);
  else return MalVectorNth(m, n);
}

INT MalSize(Malval *m)
{
  NullCheck(m, "malval");
  if (MalIsList(m)) return MalListSize(m);
  else if (MalIsVector(m)) return MalVectorSize(m);
  else return 0;
}

Malval *MalCons(Malval *x, Malval *l)
{
  if (MalIsVector(l)) {
    return MalListCons(x, MalListOfVector(l));
  }
  else {
    return MalListCons(x, l);
  }
}

#endif
