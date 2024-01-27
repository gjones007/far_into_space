.ONESHELL:

# Add any project C files here to have them built as part of the project.
PROJECT_SOURCE_FILES ?= main.c

# This is hardcoded to the path that `install-linux.sh` and `install-windows.bat` 
# place emsdk files to avoid needing to set up the environment to build.
CC=emcc 

# This is the directory within `src` where the finished files will be placed.
DEST=./build

CFLAGS=-I./external -s USE_GLFW=3 -sSTACK_SIZE=1MB -DRAYGUI_IMPLEMENTATION -s STACK_OVERFLOW_CHECK=1 --preload-file resources -sSAFE_HEAP=0 -sERROR_ON_UNDEFINED_SYMBOLS=0 --shell-file ./minshell.html
MAKE=make

OBJ=$(patsubst %.c, %.o, $(PROJECT_SOURCE_FILES)) ./external/libraylib.a ./external/libbox2d.a

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

index.html: $(OBJ) odin.wasm.a
	mkdir -p $(DEST)
	$(CC) -o $(DEST)/$@ $^ $(CFLAGS)

odin.wasm.a:
	odin build src -target:freestanding_wasm32 -o:size -debug -out:odin.o -no-entry-point -extra-linker-flags:"--import-memory -zstack-size=8096 --initial-memory=65536 --max-memory=65536 --global-base=6560 --gc-sections"
	#odin build src -target:freestanding_wasm32 -o:size -out:odin.o -no-entry-point -extra-linker-flags:"--import-memory -zstack-size=8096 --initial-memory=65536 --max-memory=65536 --global-base=6560 --gc-sections"
	llvm-ar rc $@ odin.wasm.o

clean:
	rm *.o odin.wasm.a
	rm -rf ./build
