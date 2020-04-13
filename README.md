![](https://github.com/JeffIrwin/life/workflows/CI/badge.svg)

# life
Conway's game of life in Fortran

## Compile
The GNU Fortran compiler works on Windows and Linux (at least):

    gfortran -o life life.f

## Run
The `life` program takes input from stdin:

    cd inputs
    ../life.exe < acorn.inp

where `acorn.inp` configures a few input options:

    "acorn.rle"           seed filename
    100                   number of generations
    y                     write results? (y/n)
    -150 -100 150 150     bounding box: min x, min y, max x, max y
    n                     transpose image frames? (y/n)
    n                     invert image B/W colors? (y/n)

The order of the lines matters, and only end-of-line comments work after the expected number of input arguments for each line.

Several seed formats are supported, including the popular run-length encoded `.rle` format, many examples of which can be found on https://www.conwaylife.com/forums

Two different plain-text formats with the seed in a matrix of characters are supported.  See for example [bunnies.cells](inputs/bunnies.cells) or [glider.txt](inputs/glider.txt).

## Stitch image frames into a video
Use [FFmpeg](https://www.ffmpeg.org/download.html) to make a video.  From the `inputs` directory:

    ffmpeg -i ./frames/acorn_%d.pbm -c:v libx264 -pix_fmt yuv420p acorn-out-0.mp4

## Sample output
https://www.youtube.com/watch?v=2m9aPL1qjo0
