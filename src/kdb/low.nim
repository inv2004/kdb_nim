import kdb/low/ipc_async
export ipc_async

# this module reexport all child dependencies in the following way:
#     ipc -> format + procs -> converters -> bindings -> types

initMemory()
