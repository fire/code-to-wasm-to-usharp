from wasmer import engine, wasi, Store, Module, Instance
from wasmer_compiler_cranelift import Compiler
import sys

wasm_path = "build/flite.wasm"

store = Store(engine.Universal(Compiler))
module = Module(store, open(wasm_path, 'rb').read())

wasi_env = wasi.StateBuilder('wasi_test_program').argument('hello').finalize()
import_object = wasi_env.generate_import_object(store, wasi.get_version(module, strict=True))
instance = Instance(module, import_object)

def fill_buffer(s):
	data = s.encode() + b"\0"
	buf = instance.exports.get_buffer()
	mem = memoryview(instance.exports.memory.buffer)
	mem[buf:buf+len(data)] = data
	return buf

instance.exports._initialize()
instance.exports.init()
instance.exports.cmu_lex_lookup(fill_buffer(sys.argv[1]))