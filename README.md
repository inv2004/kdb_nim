# Nim to Kdb type-safe bindings
[![](https://github.com/inv2004/kdb_nim/workflows/Tests/badge.svg)](https://github.com/inv2004/kdb_nim/actions?query=workflow%3ATests)

**Kdb** is a column-oriented database https://kx.com with built-in Q and K languages. It is quite popular for financial and time-series analytics.

**Nim** is a statically typed compiled programming language with an optional GC https://nim-lang.org. It compiles to very efficient C code, that is why its' speed is often near or equals the vanilla-C implementation. In addition Nim shares a lot of Python-like aspects like syntax and simplicity of usage.

### Reason
The goal of this package is not only to provide bindings between the two languages, but to build statically-checked code and structures on top of Kdb, which, due to it's duck-typed nature leads to a lot of exceptions and runtime errors in Kdb projects.

### Features / TODO:
- [x] Support all Kdb types in low-level binding
- [x] Automatic memory management
- [x] IPC + Sync Reply
- [x] Implicit casting between Nim and Kdb types
- [x] Iterators and mutable iterators
- [x] Separate types for static garanties
- [x] Generic types for K-structures
- [x] Async-await IO/IPC dispatching
- [x] IPC Routing macro
- [ ] Native implementation without k bindings
- [ ] Historical files access
- [ ] Translate the package into Java/Scala/Kotlin/Rust (by request)

### Advantages
Except low-level binding from ``kdb/low``, the main goal the library to interact via high-level type-checked interface.
The best way to understand the advantages of this package is by going through an example:

#### Init part
**updated to async**

Code to run on q-server side to simulate stream data after some-kind of subscription:
```kdb
.u.sub:{[x;y;z] system"t 1000"; .z.ts:{[x;y] -1 .Q.s2 x(`enrich;([] n:10?5))}[.z.w]; (1b; `ok)}
```

Full code is here [enrich_req.nim](/examples/enrich_req.nim)

Nim-client:
```nim
type
  RequestT = object of RootObj
    n: int

  ReplyT = object of RequestT
    s: Sym

defineTable(RequestT)
defineTable(ReplyT)
```
One of the main ideas of the library is to help to catch all type-related errors during compile time. That's why the first thing we want is to define schema for the tables we use. We generate the schema by ``defineTable`` declaration from basic language structures which represent a row of our table.

Another point is that Nim has inheritance for structures, and we can use it, so the table ``ReplyT`` actually has two fields: ``s`` and ``n`` from ``RequestT``.

``defineTable`` automatically generates a functions to interact with the table according to the struct's fields and types during compiletime, not runtime.

```nim
let client = waitFor asyncConnect("your-server", 9999)

let rep = waitFor client.asyncCall[:(bool, Sym)](".u.sub", 123.456, "str", s"sym")
echo rep
```
I would like to point out that we provide a type for call function - and it converts the reply from kdb-side into the provided type if possible. Also, we have implicit converter from nim-types into kdb-structures, so we put most of the types into the function arguments without conversion.

There is also a ``Sym`` type with an ``s`` constructor to easily distinguish sym from string kdb-types, but if you have Sym in the table, functions like add or transform will implicitly convert string into Sym

#### Main part

```nim
serve(client):
  proc enrich(data: KTable[RequestT]): KTable[ReplyT] =
```
The serve macros generate simple routing for IPC-calls. So, if external server or client will call ``enrich`` procedure on the process - it will find definition provided in ``serve`` block and will call it. Also, the function can check that the data received from kdb-side matches the scheme for the table we defined and throw an exception otherwise.

```nim
    let symCol = data.n.mapIt(d.getOrDefault(it))
```
Here we generate a new column for our reply, see how we can access table's fields (``n`` here) and if we made a mistake and typed ``nn`` then we would've had a compilation error: ``Error: undeclared field: 'nn'``.

```nim
    result = data.transform(ReplyT, symCol)
```
``transform`` function was made to transform tables from one schema to another. By default it makes in-place transformation, so we do not copy the data, but internally enrich low-level kdb data with the new columns or delete some if necessary. We do not need old ``data`` anymore, ``data`` is not available after this transformation. So, to transform ``RequestT`` into ``ReplyT`` we have to add one more column and we provide it in the argument to the function. If ``transform`` does not have arguments except the type, then the column is created with default values for the column's type.

It's important point out that we also do type checking here. If we try to put floats into the Sym column for some reasons, we will get a compilation error: ``Error: transform error: expected: Sym, provided: float``

```nim
    result.add(ReplyT(n: 100, s: "hundred"))
    echo result
```
Nim distinguishes between mutable and immutable data, by default result of the procedure is mutable, and it helps us because we are going to modify it by adding row. If we provided a wrong struct or types into the ``add`` function then we would get compilation error, I specifically mentioned this because in kdb the problem can only be found at runtime or even in production.

Additional point that the library automatically detects is it sync or async call and sends reply back according to the requested message type, but it does not block thread in any case, because all logic is implemented in Nim's asynchronous IO.

All types implement the output interface, so you will see a reply after ``echo``
```nim
┌─────┬─────────┐
│ n   │ s       │
├─────┼─────────┤
│ 2   │ two     │
│ 4   │         │
│ 3   │ three   │
.     .         .
│ 100 │ hundred │
└─────┴─────────┘
````

```nim
runForever()
```
The lib supports asyncdispatch module of the Nim language, that is why we start main event loop here.

