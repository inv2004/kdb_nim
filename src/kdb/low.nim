import kdb/low/ipc
export ipc

# this module reexport all child dependencies in the following way:
#     ipc -> format + procs -> converters -> bindings -> types

initMemory()
