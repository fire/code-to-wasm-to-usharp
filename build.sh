#!/usr/bin/env bash

HERE=$(cd $(dirname $0); pwd)

# download flite
if [ ! -d flite ]; then
    git clone https://github.com/festvox/flite
fi

# build flite
cd $HERE/flite
if [ ! Makefile ]; then
	./configure --host=wasm32-wasi \
		CC=${WASI_SDK_PATH}/bin/clang \
		AR=${WASI_SDK_PATH}/bin/llvm-ar \
		RANLIB=${WASI_SDK_PATH}/bin/llvm-ranlib
fi
(cd src && make && make ../build/wasm32-wasi/obj/src/.build_lib)
(cd lang/cmulex && make ../../build/wasm32-wasi/obj/lang/cmulex/.build_lib)

# build main
mkdir -p $HERE/build
cd $HERE/flite
${WASI_SDK_PATH}/bin/clang -DDIE_ON_ERROR -DCST_NO_SOCKETS -DWASM32_WASI \
	-Ilang/usenglish -Iinclude -Lbuild/wasm32-wasi/lib -lflite -lflite_cmulex \
	-mexec-model=reactor \
	-Wl,--export=cmu_lex_lookup -Wl,--export=get_buffer -Wl,--export=init \
	-o ../build/flite.wasm ../flite.c

${WASI_SDK_PATH}/bin/clang -DDIE_ON_ERROR -DCST_NO_SOCKETS -DWASM32_WASI \
	-Ilang/usenglish -Iinclude -Lbuild/wasm32-wasi/lib -lflite -lflite_cmulex \
	-mexec-model=reactor \
	-Wl,--export=cmu_lex_lookup -Wl,--export=get_buffer \
	-o ../build/flite.noinit.wasm ../flite.c

# strip functions only used by init
cd $HERE/build
wasm2wat --enable-all flite.wasm -o flite.wat
wasm2wat --enable-all flite.noinit.wasm -o flite.noinit.wat
python3 ../wasm_strip_func.py flite.wat flite.noinit.wat
wat2wasm --enable-all flite.wat -o flite.opt.wasm
wasm-opt --enable-bulk-memory --enable-sign-ext --remove-unused-module-elements --strip-debug flite.opt.wasm -o flite.opt.wasm
# twiggy paths flite.noinit.wasm > flite.noinit.txt

# export memory
python3 ../wasm_save_mem.py flite.wasm . memory.bytes

# export udonsharp
wasm2usharp flite.opt.wasm -o WasmFlite.cs
sed -i -E '/w2us_data[0-9]+ = /d' WasmFlite.cs
sed -i -E '/w2us_data[0-9]+[.]CopyTo/d' WasmFlite.cs
sed -i -E '/w2us_null/d' WasmFlite.cs
sed -i 's/class_wasi_snapshot_preview1/Flite/' WasmFlite.cs
sed -i 's/using UdonSharp/using ShaderGPT.Udon/' WasmFlite.cs
sed -i 's/UdonSharpBehaviour/UdonMonoBehaviour/' WasmFlite.cs