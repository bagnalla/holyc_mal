#ifndef INTERP_HC
#define INTERP_HC

#include "Core.HC"
#include "Env.HC"
#include "GC.HC"
#include "Intrinsics.HC"
#include "Lexer.HC"
#include "MalList.HC"
#include "MalListVector.HC"
#include "PArray.HC"
#include "PrimitiveTypes.HC"
#include "Printer.HC"
#include "Reader.HC"
#include "String.HC"

Malval *READ(String *s)
{
  Reader *r = ReaderMk;
  Malval *m = NULL;
  try {
    m = ReaderReadString(r, s);
  }
  catch {
    ReaderDelete(r);
    RethrowException; // just to be explicit
  }
  ReaderDelete(r);
  return m;
}

BOOL IsSpecial(Malval *v) {
  if (v->_tag != ATOM) return FALSE;
  if (v->_atom->_tag != ATOM_SYMBOL) return FALSE;
  String *s = v->_atom->_str;
  return
    StringEqC(s, "def!") || StringEqC(s, "let*") || StringEqC(s, "do") ||
    StringEqC(s, "if") || StringEqC(s, "fn*") || StringEqC(s, "eval") ||
    StringEqC(s, "quote") || StringEqC(s, "quasiquote") ||
    StringEqC(s, "defmacro!") || StringEqC(s, "macroexpand") ||
    StringEqC(s, "try*") || StringEqC(s, "quit!");
}

BOOL IsPair(Malval *v) {
  if (MalIsList(v)) return MalListSize(v);
  else if (MalIsVector(v)) return MalVectorSize(v);
  else return 0;
}

Malval *mkQuote(Malval *v)
{
  Malval *q = MalSymbolMk(StringMk("quote"));
  List *l = ListCons(q, ListCons(v, ListNil));
  return MalListMk(l);
}

Malval *quasiquote (Malval *ast)
{
  List *l;
  Malval *v, *v1;
  if (!IsPair(ast)) {
    l = ListCons(MalSymbolMk(StringMk("quote")),
		       ListCons(ast, ListNil));
    return MalListMk(l);
  }
  else {
    v = MalHead(ast);
    if (MalIsSymbol(v)) {
      if (StringEqC(v->_atom->_str, "unquote")) {
	if (ListSize(ast->_list) < 2) {
	  throws("unquote requires an argument");
	}
	return MalNth(ast, 1);
      }
      else goto _quasiquote_l1; // deal with no short-circuiting AND
    }
    else {
    _quasiquote_l1:
      if (IsPair(v)) {
	v1 = MalHead(v);
	if (MalIsSymbol(v1)) {
	  if (StringEqC(v1->_atom->_str, "splice-unquote")) {
	    l = ListCons(MalSymbolMk(StringMk("concat")),
			 ListCons(MalNth(v, 1),
				  ListCons(quasiquote(MalTail(ast)),
					   ListNil)));
	    return MalListMk(l);
	  }
	}
      }
      // otherwise
      l = ListCons(MalSymbolMk(StringMk("cons")),
		   ListCons(quasiquote(v),
			    ListCons(quasiquote(MalTail(ast)),
				     ListNil)));
      return MalListMk(l);
    }
  }
}

BOOL isMacroCall(Env *env, Malval *ast)
{
  Malval *m, *macro;
  if (MalIsList(ast)) {
    if (MalListSize(ast) > 0) {
      m = MalHead(ast);
      if (MalIsSymbol(m)) {
	macro = EnvGet(env, StringOfMalval(m));
	if (macro)
	  return MalIsMacro(macro);
      }
    }
  }
  return FALSE;
}

VOID _bindEnv(Env *env, PArray *binders, Malval *ast)
{
  INT i, k;
  String *binder;
  List *l;
  for (i = 0; i < PArraySize(binders); ++i) {
    binder = StringCopy(PArrayGet(binders, i));
    if (StringEqC(binder, "&")) {
      if (i >= PArraySize(binders) - 1) {
	throws("naked '&' in function arguments");
      }
      else {
	binder = StringCopy(PArrayGet(binders, ++i));
	l = ListNil;
	for (k = MalListSize(ast)-1; k >= i-1; --k) {
	  l = ListCons(MalListNth(ast, k), l);
	}
	EnvSet(env, binder, MalListMk(l));
	i = MalListSize(ast) - 1; // prevent error
	break;
      }
    }
    else {
      if (i >= MalListSize(ast)) {
	throws("not enough arguments to function");
      }
      else {
	EnvSet(env, binder, MalListNth(ast, i));
      }
    }
  }
  if (i < MalListSize(ast) - 1) {
    throws("too many arguments to function");
  }
}

Env *_bindClosureEnv(Env *env, PArray *binders, Malval *ast)
{
  Env *new_env = EnvEmpty(env);
  _bindEnv(new_env, binders, MalListTail(ast));
  return new_env;
}

extern Malval *EVAL(Env *env, Malval *m);

Malval *macroExpand(Env *env, Malval *ast)
{
  Malval *v1, *macro, *body;
  Closure *clos;
  Env *clos_env, *new_env;
  PArray *binds;
  while (isMacroCall(env, ast)) {
    v1 = MalListHead(ast);
    macro = EnvGet(env, v1->_atom->_str);
    clos = macro->_fun->_clos;
    clos_env = macro->_fun->_env;
    binds = clos->_binds;
    body = clos->_body;
    new_env = _bindClosureEnv(clos_env, binds, ast);
    ast = EVAL(new_env, body);
  }
  return ast;
}

BOOL _isCatch(Malval *ast)
{
  Malval *v;
  if (ast) {
    if (MalListSize(ast)) {
      v = MalListNth(ast, 0);
      if (MalIsSymbol(v))
	return StringEqC(StringOfMalval(v), "catch*");
    }
  }
  return FALSE;
}

Malval *mkCatchClosure(Env *env, Malval *catchTerm)
{
  PArray *binds = PArrayEmpty;
  PArrayPush(binds, StringOfMalval(MalListNth(catchTerm, 1)));
  return MalFunUserMk(env, binds, MalListNth(catchTerm, 2));
}

/* // Map EVAL over a list */
/* List *_map_eval(Env *env, List *l) */
/* { */
/*   Malval *head; */
/*   List *tail; */
/*   switch (l->_tag) { */
/*   case LIST_NIL: */
/*     return ListNil; */
/*   case LIST_CONS: */
/*     head = EVAL(env, l->_head); */
/*     GC_push(head); */
/*     tail = _map_eval(env, l->_tail); */
/*     GC_pop; */
/*     return ListCons(head, tail); */
/*   default: */
/*     return throws("_map_eval: unknown list tag"); */
/*   } */
/* } */

// This version of _map_eval avoids recursive calls. It's a little slower.
List *_map_eval(Env *env, List *l)
{
  List *cur = l;
  List *copy = ListNil;
  INT i, n = 1;
  Malval *x;
  GC_push(copy);
  while (!ListIsNil(cur)) {
    switch (cur->_tag) {
    case LIST_CONS: {
      x = EVAL(env, ListHead(cur));
      copy = ListCons(x, copy);
      GC_push(copy); n++;
      cur = ListTail(cur);
      break;
    }
    case LIST_NIL:
      return throws("_map_eval: shouldn't be nil");
    default:
      return throws("_map_eval: unknown list tag");
    }
  }
  for (i = 0; i < n; ++i) GC_pop;
  return ListRev(copy);
}

Malval *eval_ast(Env *env, Malval *m)
{
  INT i;
  CHAR *c;
  Malval *_m, *new_tab, *k, *val;
  String *s;
  List *l;
  PArray *pa, *keys;
  Hashmap *tab;
  if (IsSpecial(m)) return MalvalCopy(m);
  switch (m->_tag) {
  case ATOM:
    if (m->_atom->_tag == ATOM_SYMBOL) {
      _m = EnvGet(env, StringOfMalval(m));
      if (!_m) {
	c = StringCString(StringOfMalval(m));
	s = StringMk("'");
	StringConcatC(s, c);
	StringConcatC(s, "' not found");
	Free(c);
	throwval(MalStringMk(s));
      }
      return _m;
    }
    return m;
  case LIST: {
    GC_push(m);
    l =_map_eval(env, m->_list);
    GC_pop;
    return MalListMk(l);
  }
  case VEC: {
    pa = PArrayEmpty;
    GC_push(m); GC_push(pa);
    for (i = 0; i < MalSize(m); ++i) {
      PArrayPush(pa, EVAL(env, MalNth(m, i)));
    }
    GC_pop; GC_pop;
    return MalVectorMk(pa);
  }
  case FUN:
    if (MalIsIntrinsic(m))
      m->_fun->_env = env;
    return m;
  case HASH: {
    tab = HashmapOfMalval(m);
    keys = RemoveDuplicateMalvals(HashmapKeys(tab));
    new_tab = MalHashMk(HashmapEmpty);
    GC_push(m); GC_push(keys); GC_push(new_tab);
    for (i = 0; i < PArraySize(keys); ++i) {
      k = PArrayGet(keys, i);
      val = HashmapGet(tab, k);
      MalHashSet(new_tab, k, EVAL(env, val));
    }
    GC_pop; GC_pop; GC_pop;
    return new_tab;
  }
  case REF:
    return m;
  };
  return throws("eval_ast: unknown malval tag");
}

Malval *EVAL(Env *env, Malval *ast)
{
  INT i, stack_size;
  CHAR *c;
  Malval *eval_result = NULL;
  Malval *v1, *key, *val, *binds, *temp, *result, *b, *body;
  Malval *bind_symbols, *sym, *intermediate, *catchTerm, *_ast;
  Malval *catchClosure;
  String *s, *tag;
  Env *temp_env, *clos_env;
  Exception *e;
  Closure *clos;
  PArray *binds_arr;
  while (TRUE) {
  BEGIN_EVAL_LOOP:;
    /* StringPrintLn(PrintMalval(ast, TRUE, TRUE)); */
    stack_size = GC_stack_size;
    GC_push(env); GC_push(ast);
    /* print_GC_status; */
    check_for_GC;

    switch (ast->_tag) {
    case ATOM:
    case FUN:
    case REF:
      eval_result = eval_ast(env, ast);
      goto EXIT_EVAL_LOOP;
    case LIST: {
      if (!MalListSize(ast)) {
	eval_result = ast;
	goto EXIT_EVAL_LOOP;
      }
      else { // nonempty list

	/* Do macro expansion */
	ast = macroExpand(env, ast);
	GC_pop;
	GC_push(ast);
	if (!MalIsList(ast)) {
	  eval_result = eval_ast(env, ast);
	  goto EXIT_EVAL_LOOP;
	}

	v1 = MalListHead(ast);

	// SPECIAL FORMS
	if (IsSpecial(v1)) {

	  // quit!
	  if (StringEqC(v1->_atom->_str, "quit!")) {
	    throws("quit!");
	  }

	  // def!
	  if (StringEqC(v1->_atom->_str, "def!")) {
	    if (MalListSize(ast) < 3) {
	      throws("'def!' requires 2 arguments");
	    }
	    s = NULL;
	    val = NULL;
	    s = StringOfMalval(MalListNth(ast, 1));
	    GC_push(s);
	    val = EVAL(env, MalListNth(ast, 2));
	    GC_pop;
	    EnvSet(env, s, val);
	    eval_result = MalvalCopy(val);
	    goto EXIT_EVAL_LOOP;
	  }

	  // defmacro!
	  if (StringEqC(StringOfMalval(v1), "defmacro!")) {
	    if (MalListSize(ast) < 3) {
	      throws("'defmacro!' requires 2 arguments");
	    }
	    s = NULL;
	    val = NULL;
	    s = StringOfMalval(MalListNth(ast, 1));
	    GC_push(s);
	    val = EVAL(env, MalListNth(ast, 2));
	    GC_pop;
	    if (!MalIsClosure(val)) {
	      throws("defmacro! expects a closure");
	    }
	    MalSetIsMacro(val, TRUE);
	    EnvSet(env, s, val);
	    eval_result = MalvalCopy(val);
	    goto EXIT_EVAL_LOOP;
	  }

	  // macroexpand
	  else if (StringEqC(StringOfMalval(v1), "macroexpand")) {
	    if (MalListSize(ast) != 2) {
	      throws("'macroexpand' requires 1 argument");
	    }
	    v1 = MalListNth(ast, 1);
	    eval_result = macroExpand(env, v1);
	    goto EXIT_EVAL_LOOP;
	  }

	  // let*
	  else if (StringEqC(StringOfMalval(v1), "let*")) {
	    temp_env = EnvEmpty(env);
	    if (MalListSize(ast) < 3) {
	      throws("'let*' requires 2 arguments");
	    }
	    binds = MalListNth(ast, 1);
	    if (MalIsVector(binds)) {
	      binds = MalListOfVector(binds);
	    }
	    if (MalListSize(binds) % 2) {
	      throws("uneven number of 'let*' bind arguments");
	    }
	    GC_push(temp_env); GC_push(binds);
	    for (i = 0; i < MalListSize(binds); i += 2) {
	      key = MalListNth(binds, i);
	      if (key->_tag == ATOM) {
		if (key->_atom->_tag != ATOM_SYMBOL)
		  throws("'let*' bind argument must be a symbol");
		val = EVAL(temp_env, MalListNth(binds, i+1));
		EnvSet(temp_env, StringOfMalval(key), val);
	      }
	      else
		throws("'let*' bind argument must be a symbol");
	    }
	    GC_pop; GC_pop;
	    env = temp_env;
	    ast = MalListNth(ast, 2);
	    goto RESTART_EVAL_LOOP;
	  }

	  // do
	  else if (StringEqC(StringOfMalval(v1), "do")) {
	    if (MalListSize(ast) < 2) {
	      throws("'do' requires at least one argument");
	    }
	    temp = NULL;
	    result = NULL;
	    for (i = 1; i < MalListSize(ast) - 1; ++i) {
	      temp = EVAL(env, MalListNth(ast, i));
	    }
	    ast = MalListNth(ast, MalListSize(ast)-1);
	    goto RESTART_EVAL_LOOP;
	  }

	  // if
	  else if (StringEqC(StringOfMalval(v1), "if")) {
	    if (MalListSize(ast) < 3) {
	      throws("'if' requires at least two arguments");
	    }
	    b = NULL;
	    result = NULL;
	    b = EVAL(env, MalListNth(ast, 1));
	    // True branch
	    if (MalIsTruthy(b)) {
	      ast = MalListNth(ast, 2);
	    }
	    // False branch
	    else {
	      if (MalListSize(ast) > 3)
		ast = MalListNth(ast, 3);
	      else
		result = MalNilMk;
	    }
	    if (result) {
	      eval_result = result;
	      goto EXIT_EVAL_LOOP;
	    }
	    else
	      goto RESTART_EVAL_LOOP;
	  }

	  // fn*
	  else if (StringEqC(StringOfMalval(v1), "fn*")) {
	    if (MalListSize(ast) != 3) {
	      throws("'fn*' requires exactly two arguments");
	    }
	    result = NULL;
	    binds_arr = PArrayEmpty;
	    body = NULL;
	    bind_symbols = MalListNth(ast, 1);
	    for (i = 0; i < MalSize(bind_symbols); ++i) {
	      sym = MalNth(bind_symbols, i);
	      PArrayPush(binds_arr, StringOfMalval(sym));
	    }
	    body = MalvalCopy(MalListNth(ast, 2));
	    result = MalFunUserMk(env, binds_arr, body);
	    eval_result = result;
	    goto EXIT_EVAL_LOOP;
	  }

	  // eval
	  else if (StringEqC(StringOfMalval(v1), "eval")) {
	    if (MalListSize(ast) != 2) {
	      throws("'eval' requires exactly one argument");
	    }
	    intermediate = EVAL(env,
				MalListNth(ast, MalListSize(ast)-1));
	    ast = intermediate;
	    env = EnvRoot(env);
	    goto RESTART_EVAL_LOOP;
	  }

	  // quote
	  else if (StringEqC(StringOfMalval(v1), "quote")) {
	    if (MalListSize(ast) != 2) {
	      throws("'quote' requires exactly one argument");
	    }
	    eval_result = MalListNth(ast, 1);
	    goto EXIT_EVAL_LOOP;
	  }

	  // quasiquote
	  else if (StringEqC(StringOfMalval(v1), "quasiquote")) {
	    if (MalListSize(ast) != 2) {
	      throws("'quasiquote' requires exactly one argument");
	    }
	    ast = quasiquote(MalListNth(ast, 1));
	    goto RESTART_EVAL_LOOP;
	  }

	  // try
	  else if (StringEqC(StringOfMalval(v1), "try*")) {
	    if (MalListSize(ast) != 3) {
	      throws("'try*' requires exactly two arguments");
	    }
	    body = MalListNth(ast, 1);
	    catchTerm = MalListNth(ast, 2);
	    if (!_isCatch(catchTerm)) {
	      throws("'try*' must have an accompanying 'catch*'");
	    }
	    if (MalListSize(catchTerm) != 3) {
	      throws("'catch*' must have exactly two arguments");
	    }
	    try {
	      ast = EVAL(env, body);
	    }
	    catch {
	      CatchException; // Stop it from bubbling up
	      e = GetException;
	      val = ExceptionMalval(e);
	      ExceptionDelete(e);
	      // quote the exception value so it doesn't get evaluated
	      val = mkQuote(val);
	      _ast = MalListNil;
	      catchClosure = mkCatchClosure(env, catchTerm);
	      _ast = MalListPush(_ast, catchClosure);
	      _ast = MalListPush(_ast, val);
	      GC_push(val); GC_push(_ast); GC_push(catchClosure);
	      ast = EVAL(env, _ast);
	      GC_pop; GC_pop; GC_pop;
	    }
	    goto RESTART_EVAL_LOOP;
	  }
	  else {
	    throws("unknown special symbol");
	  }
	}
	else {
	  _ast = eval_ast(env, ast);
	  v1 = MalListHead(_ast);
	  if (v1->_tag == FUN) { // else do standard application
	    switch (v1->_fun->_tag) {

	      // INTRINSIC FUNCTION
	    case FUN_INTRINSIC: {
	      GC_push(_ast);
	      result = (*v1->_fun->_f)(_ast);
	      GC_pop;
	      eval_result = result; // return the result of application
	      goto EXIT_EVAL_LOOP;
	    }

	      // CLOSURE FUNCTION
	    case FUN_USER: {
	      v1 = MalListHead(_ast);
	      clos = v1->_fun->_clos;
	      clos_env = v1->_fun->_env;
	      binds = clos->_binds;
	      body = clos->_body;
	      env = _bindClosureEnv(clos_env, binds, _ast);
	      ast = body;
	      goto RESTART_EVAL_LOOP;
	    }
	      
	    default:
	      /* "unknown function tag: %d\n", v1->_fun->_tag; */
	      throws("unknown function tag");
	    }
	    
	  }
	  else { // error - can't apply a non function
	    tag = PrintMalval(v1, TRUE, TRUE);
	    c = StringCString(tag);
	    "Can't apply '%s' like a function\n", c;
	    Free(c);
	    throws("illegal application");
	  }
	}
      }
      break;
    }
    case VEC:
    case HASH:
      eval_result = eval_ast(env, ast);
      goto EXIT_EVAL_LOOP;
    default:
      /* "EVAL: unknown malval tag %d\n", ast->_tag; */
      throws("EVAL: unknown malval tag");
    }
  }
 EXIT_EVAL_LOOP:
  GC_pop; GC_pop;
  return eval_result;
 RESTART_EVAL_LOOP:
  GC_pop; GC_pop;
  goto BEGIN_EVAL_LOOP;
}

String *PRINT(Malval *m)
{
  return PrintMalval(m, TRUE, TRUE);
}

Env *_init_env()
{
  Env *env = EnvEmpty(NULL);
  Env *ns = _ns(env);
  PArray *keys = EnvKeys(ns);
  INT i;
  String *k;
  for (i = 0; i < PArraySize(keys); ++i) {
    k = StringOfMalval(PArrayGet(keys, i));
    EnvSet(env, k, EnvGet(ns, k));
  }
  return env;
}

BOOL rep(Env *env, String *s, BOOL print)
{
  Malval *ast_in = NULL, *ast_out = NULL;
  String *res = NULL;
  Exception *e;
  BOOL exit = FALSE;
  try {
    ast_in = READ(s);
    ast_out = EVAL(env, ast_in);
    if (print) {
      res = PRINT(ast_out);
      StringPrintLn(res);
    }
  }
  catch {
    e = GetException;
    res = ExceptionString(e);
    CatchException;
    ExceptionDelete(e);
    exit = StringEqC(res, "quit!");
    if (exit) "Exiting Mal.\n";
    else StringPrintLn(res);
  }
  return exit;
}

INT mal(...)
{
  init_GC;
  
  String *s = StringEmpty;
  Env *env = _init_env;

  GC_push(s);
  set_GC_root_env(env);

  // Prelude definitions
  StringConcatC(s, "(def! not (fn* (a) (if a false true)))");
  rep(env, s, FALSE);
  StringClear(s);
  StringConcatC(s, "(def! load-file (fn* (f) (eval (read-string (str \"(do \" (slurp f) \")\")))))");
  rep(env, s, FALSE);
  StringClear(s);
  StringConcatC(s, "(defmacro! cond (fn* (& xs) (if (> (count xs) 0) (list 'if (first xs) (if (> (count xs) 1) (nth xs 1) (throw \"odd number of forms to cond\")) (cons 'cond (rest (rest xs)))))))");
  rep(env, s, FALSE);
  StringClear(s);
  StringConcatC(s, "(def! *gensym-counter* (atom 0))");
  rep(env, s, FALSE);
  StringClear(s);
  StringConcatC(s, "(def! gensym (fn* [] (symbol (str \"G__\" (swap! *gensym-counter* (fn* [x] (+ 1 x)))))))");
  rep(env, s, FALSE);
  StringClear(s);
  StringConcatC(s, "(defmacro! or (fn* (& xs) (if (empty? xs) nil (if (= 1 (count xs)) (first xs) (let* (condvar (gensym)) `(let* (~condvar ~(first xs)) (if ~condvar ~condvar (or ~@(rest xs)))))))))");
  rep(env, s, FALSE);
  StringClear(s);

  INT i;
  PArray *args = PArrayEmpty;
  for (i = 1; i < argc; ++i) {
    PArrayPush(args, MalStringMk(StringMk(argv[i])));
  }
  EnvSet(env, StringMk("*ARGV*"), MalListMk(ListFromPArray(args)));
  EnvSet(env, StringMk("*host-language*"), MalStringMk(StringMk("HolyC")));

  CHAR *cstr;
  if (argc > 0) {
    StringConcatC(s, "(load-file \"");
    StringConcatC(s, argv[0]);
    StringConcatC(s, "\")");
    rep(env, s, FALSE);
    StringClear(s);
  }
  else {
    check_for_GC;
    "Mal [HolyC]\n";
    while (TRUE) {
      cstr = GetStr("user> ");
      s = StringMk(cstr);
      Free(cstr);
      if (!StringEqC(s, "")) {
	if (rep(env, s, TRUE))
	  break;
      }
    }
  }

  cleanup_GC;
  return 0;
}

#endif
