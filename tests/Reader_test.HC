#include "Env.HC"
#include "Exception.HC"
#include "GC.HC"
#include "PrimitiveTypes.HC"
#include "Printer.HC"
#include "Reader.HC"
#include "String.HC"
#include "Types.HC"

init_GC;

Env *env = EnvEmpty(NULL);
set_GC_root_env(env);

Reader *r = ReaderMk();
Malval *m = MalNilMk;
Exception *e;
try {
  m = ReaderReadString(r, StringMk("(+ 1 2)"));
}
catch {
  /* CatchException(); */
  ReaderDelete(r);
  Exception *e = GetException();
  m = ExceptionMalval(e);
  StringPrintLn(PrintMalval(m, TRUE, TRUE));
}
ReaderDelete(r);

StringPrintLn(PrintMalval(m, TRUE, TRUE));

cleanup_GC;
;
