// Functions for working with number Malvals

#ifndef MALNUMBER_HC
#define MALNUMBER_HC

#include "Util.HC"
#include "PArray.HC"
#include "Types.HC"
#include "Util.HC"

BOOL MalIsNumber(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag == ATOM)
    return m->_atom->_tag == ATOM_NUMBER;
  else return FALSE;
}

Malval *MalNumberMk(INT n)
{
  Malval *m = _MalMk;
  m->_tag = ATOM;
  Atom *a = MAlloc(sizeof(Atom));
  a->_tag = ATOM_NUMBER;
  a->_num = n;
  m->_atom = a;
  m->_metadata = MalNilMk;
  return m;
}

INT MalIntOfNumber(Malval *m)
{
  NullCheck(m, "malval");
  if (m->_tag != ATOM) {
    throws("expected number");
  }
  if (m->_atom->_tag != ATOM_NUMBER) {
    throws("expected number");
  }
  return m->_atom->_num;
}


#endif
