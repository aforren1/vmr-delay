# build special encode/decode for JSON
# they're *way* faster than the ones available
# in the io package, and I don't think we can/should target
# octave 7 yet, which has builtin jsonencode/jsondecode
all: build

build:
	mkoctfile --mex matlab-json/json_decode.c matlab-json/jsmn.c -o fns/json_decode.mex
	mkoctfile --mex matlab-json/json_encode.c -o fns/json_encode.mex

clean:
	rm json_decode.mex json_encode.mex
