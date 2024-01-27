# [Raylib Slo-Jam](https://itch.io/jam/raylib-slo-jam) entry

**This game is not directly buildable without extending Raylib 5.0 and the Odin binding a little bit.  I did this to push particle buffers and allow for raymarching shaders (as point buffers) to render the asteroids to the GPU. Raylib does not support this feature directly.**

In the Odin vendor library, I extended vendor/raylib/rlgl.odin to include 
```odin
rlDrawArrays          :: proc(mode: c.int, offset: c.int, count: c.int) ---
rlBindVertexArray     :: proc(array: c.uint) ---
```

then in raylib/src/rlgl.h
```c
// passthru for glDrawArrays
void rlDrawArrays(int mode, int offset, int count)
{
    glDrawArrays(mode, offset, count);
}
 
void rlBindVertexArray(unsigned int array)
{
    glBindVertexArray(array);
}
```

You need to build Raylib then and copy the update libraries into your platforms directory, i.e. in my case Odin/vendor/raylib/linux.

You also need to build box2c (as documented below), for both native and WASM (if you build WASM).

[This](https://github.com/michaelfiber/hello-raylib-wasm/) served as a template for building WASM binaries that would run in a browser.

## Graphics from [Kenny](https://www.kenney.nl/)

    - 2D assets/Space Shooter Redux/
    - 2D assets/Space Shooter Extension/

## Sounds from [](https://opengameart.org/)

Space shooter sound fx pack 1 by Dravenx

Some of the sounds, I created.

## Music

I made for this game.

## Browser target specifics

- Renderer: WebKit WebGL
- Version:  OpenGL ES 2.0 (WebGL 1.0 (OpenGL ES 2.0 Chromium))
- GLSL:     OpenGL ES GLSL ES 1.00 (WebGL GLSL ES 1.0 (OpenGL ES GLSL ES 1.0 Chromium))

## Physics Engines

- [Odin-Box2D](https://github.com/cristhofermarques/odin-box2d/)

### Box2c build

- <https://box2d.org/documentation/md__d_1__git_hub_box2d_docs_hello.html>

```sh
CXX=clang++ CC=clang cmake -B ./build-linux -DCMAKE_BUILD_TYPE=Debug -DBOX2D_SAMPLES=OFF
```

```sh
cmake -B ./build-linux -DCMAKE_BUILD_TYPE=Debug -DBOX2D_SAMPLES=OFF -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang 
```

```sh
. ~/emsdk/emsdk_env.sh
emcmake cmake -B ./build-wasm32 -DCMAKE_BUILD_TYPE=Debug -DBOX2D_SAMPLES=OFF -DBOX2D_AVX2:BOOL=OFF
cd build-wasm32
emmake make
```

### Raylib build

```sh
. ~/emsdk/emsdk_env.sh
emcmake cmake -B ./build-wasm32 -DPLATFORM=Web -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS="-s USE_GLFW=3" -DCMAKE_EXECUTABLE_SUFFIX=".html"
cd build-wasm32
emmake make
```
