# Nim to Kdb bindings

### **Kdb** is column-oriented database https://kx.com with build-in Q and K languages. It quite popular for financial and time-series analytics.

### **Nim** is statically typed compiled programming language with optional GC https://nim-lang.org. It it generates very effective intermediate C code, that is why it is speed often is near or equal vanilla-C implementation.

### The one of reasons of the package is not only to provide bindings between the two languages, but to build statically-checked code and structures on top of duck-typed Kdb, which cause a lot of exception and errors in kdb projects.

### Features / TODO:
- [x] Support all Kdb types
- [x] Automatic memory management
- [/] Implicit casting between Nim and Kdb types
- [x] Remote connection
- [ ] Separate types for static garanties
- [ ] Historical files access
- [ ] Async-await IO dispatching
