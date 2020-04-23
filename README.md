![](https://github.com/JeffIrwin/life/workflows/CI/badge.svg)

# life
Conway's game of life in Fortran

## Compile
Use CMake, or run the provided CMake wrapper script:

    ./build.sh

## Run
The `life` program loads its input from a JSON file:

    cd inputs
    ../build/life.exe acorn.json

where `acorn.json` configures a few input options:

    {
            "Seed file": "acorn.rle",
            "Frames"   : 100,
            "Write"    : true,
            "Bounds"   : [-150, -100, 150, 150],
            "Transpose": false,
            "Invert"   : false
    }

The path to the seed file, if not absolute, must be relative to the runtime directory.

Several seed formats are supported, including the popular run-length encoded `.rle` format, many examples of which can be found on https://www.conwaylife.com/forums

Two different plain-text formats with the seed in a matrix of characters are supported.  See for example [bunnies.cells](inputs/bunnies.cells) or [factory.txt](inputs/factory.txt).  Seed format is automatically determined based on the file extension, which may not be standardized.

Images written by `life` are in the portable anymap format:
![](https://github.com/JeffIrwin/life/inputs/expected-output/acorn_99.pbm)

## Stitch image frames into a video
Use [FFmpeg](https://www.ffmpeg.org/download.html) to make a video.  From the `inputs` directory:

    ffmpeg -i ./frames/acorn_%d.pbm -c:v libx264 -pix_fmt yuv420p acorn-out-0.mp4

## Sample output
https://www.youtube.com/watch?v=2m9aPL1qjo0
