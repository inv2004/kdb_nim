# Nim to Kdb bindings
[![](https://github.com/inv2004/kdb_nim/workflows/Tests/badge.svg)](https://github.com/inv2004/kdb_nim/actions?query=workflow%3ATests)

**Kdb** is column-oriented database https://kx.com with build-in Q and K languages. It quite popular for financial and time-series analytics.

**Nim** is statically typed compiled programming language with optional GC https://nim-lang.org. It generates very effective intermediate C code, that is why it's speed often is near or equals vanilla-C implementation. In addition Nim shares a lot of Python's aspects like syntax and simplicity of usage.

### Reason
The one of reasons of the package is not only to provide bindings between the two languages, but to build statically-checked code and structures on top of duck-typed Kdb, which cause a lot of exception and errors in kdb projects.

### Features / TODO:
- [x] Support all Kdb types
- [x] Automatic memory management
- [x] IPC + Sync Replay
- [x] Implicit casting between Nim and Kdb types
- [x] Iterators and mutable iterators
- [x] Separate types for static garanties
- [x] Nested types
- [ ] Historical files access
- [ ] Async-await IO dispatching
- [ ] Translate the package into Java/Scala/Kotlin if necessary

### Advantages
