all: build

build:
	mkoctfile --mex matlab-json/json_decode.c matlab-json/jsmn.c
	mkoctfile --mex matlab-json/json_encode.c

clean:
	rm json_decode.mex json_encode.mex
