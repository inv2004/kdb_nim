# Nim to Kdb bindings
[![](https://github.com/inv2004/kdb_nim/workflows/Tests/badge.svg)](https://github.com/inv2004/kdb_nim/actions?query=workflow%3ATests)

**Kdb** is column-oriented database https://kx.com with build-in Q and K languages. It quite popular for financial and time-series analytics.

**Nim** is statically typed compiled programming language with optional GC https://nim-lang.org. It generates very effective intermediate C code, that is why it's speed often is near or equals vanilla-C implementation. In addition Nim shares a lot of Python's aspects like syntax and simplicity of usage.

### Reason
The one of reasons of the package is not only to provide bindings between the two languages, but to build statically-checked code and structures on top of duck-typed Kdb, which cause a lot of exception and errors in kdb projects.

### Features / TODO:
- [x] Support all Kdb types in low-level binding
- [x] Automatic memory management
- [x] IPC + Sync Replay
- [x] Implicit casting between Nim and Kdb types
- [x] Iterators and mutable iterators
- [x] Separate types for static garanties
- [x] Generic types for K-structures
- [ ] Async-await IO dispatching
- [ ] Historical files access
- [ ] Translate the package into Java/Scala/Kotlin (by request)

### Advantages
I suppose the best way to show advantages is ti go through the following example:

#### Init part
Code to run on q-server side to simulate stream data after some-kind of subscription:
```kdb
.u.sub:{[x;y;z] system"t 1000"; .z.ts:{[x;y] -1 .Q.s2 x(`enrich;([] n:10?5))}[.z.w]; (1b; `ok)}
```

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
One of the main idea of the library is to help to catch all type-related error during compile time, that is why the first thing we want - is to define schema for the tables we use. We generate the schema by *defineTable* declaration from basic language structures which represents row of our table.

Another point it that Nim has inheritance feature for structures, and we take it into accountm that is why table *ReplyT* has two fields: *n* and *s*.

*defineTable* automatically generates function which depends on the struct's fields and types during compilation, not runtime.

```nim
const d = {1: "one", 2: "two", 3: "three"}.toTable

let client = connect("your-server", 9999)
let rep = client.call[:(bool, Sym)](".u.sub", 123.456, "str", s"sym")
echo rep
```
I would like to demostrate that we provide type for call function - and it casts reply from kdb-side into the provided type if possible. Also, we have implicit convertor from nim-types into kdb-structures, so we put most of the types into the function arguments without conversion.

There is a type Sym with constructor *s* to easy distinct sym from string kdb-types, but if you have Sym in table, functions like add or transform will implicitly convert string into Sym

#### Main part

```nim
while true:
  let (cmd, data) = client.read(RequestT, check = true)
```
The *read* function returns called function name and *KTable* of type provided in the first parameter. Also, the function can check that data received from kdb-side matches the scheme for the table we defined and throw exception if not.

```nim
  let symCol = data.n.mapIt(d.getOrDefault(it))
```
Here we generate new column for our reply, please find that we can access for table's fields (*n* here) and if we make a mistake and typed *nn* then we have compilation error: **Error: undeclared field: 'nn'**.

```nim
  var resp = data.transform(ReplyT, symCol)
```
*transform* function was made to transform tables from one schema to another. By-default it makes in-place transformation, so we do not copy data, but internally enrich low-level kdb data with the new columns or deletes some if necessary. We do not ned old *data* anymore, *data* is not available after this transformation. So, to transform *RequesT* into *ReplyT* we have to add one more column and we provide it in argument to the function. If *transform* does not have arguments except type, when column is created with default values for the column's type.

Important point that we do type check here also, and if, for example, we want to put floats into the Sym column which will have compilation error: **Error: transform error: expected: Sym, provided: float**

```nim
  resp.add(ReplyT(n: 100, s: "hundred"))
  echo resp
  client.reply(resp)
```
Nim dictinct between mutable and immutable data, what is why for current lines defined mutable *var resp* in previous line to add one extra data into it. It we provided wrong struct or types into the *add* function we have compilation error, I point to it, because in kdb we can find the problem only in run-time, nice if not on production.

All types implements output interface, so you will see reply after *echo*
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
And the last one - just sending reply back to client. Also, please find that it is reply to *sync request*, which is not possible in standart Kdb-C-binding without additional hacks.

