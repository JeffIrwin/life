![](https://github.com/JeffIrwin/life/workflows/CI/badge.svg)

# life
Conway's game of life in Fortran

## Compile
    gfortran -o life life.f

## Run
    cd inputs
    ../life.exe < acorn.inp

## Stitch image frames into a video
(From the `inputs` directory):

    ffmpeg -i ./frames/acorn_%d.pbm -c:v libx264 -pix_fmt yuv420p acorn-out-0.mp4

## Sample output
https://www.youtube.com/watch?v=2m9aPL1qjo0
