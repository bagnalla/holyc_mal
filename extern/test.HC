// For testing HolyC interop.

Malval *testFun(Malval *args)
{
  NullCheck(args, "args");
  if (MalListSize(args) != 2) {
    return throws("'testFun' requires exactly one argument1");
  }
  Malval *v = MalListNth(args, 1);
  if (!MalIsString(v)) {
    return throws("'testFun' argument must be a string");
  }
  String *s = StringMk("your string is: ");
  StringConcat(s, StringOfMalval(v));
  return MalStringMk(s);
}
