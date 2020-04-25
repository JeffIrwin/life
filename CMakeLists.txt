
cmake_minimum_required(VERSION 3.7)

set(PROJECT life)

set(CMAKE_Fortran_FLAGS "-Wall -Wextra -fopenmp")
set(CMAKE_Fortran_FLAGS_DEBUG "-pedantic -fbounds-check -fbacktrace")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")

set(CMAKE_Fortran_COMPILER "gfortran")

project(${PROJECT} Fortran)

set(SUBMODULE_DIR submodules)

set(PNMIO pnmio)
set(JSONFORTRAN json-fortran)

add_subdirectory(${SUBMODULE_DIR}/${PNMIO})
add_subdirectory(${SUBMODULE_DIR}/${JSONFORTRAN})

add_executable(${PROJECT} life.f90)

include_directories(
	${CMAKE_CURRENT_BINARY_DIR}/${SUBMODULE_DIR}/${PNMIO}
	${CMAKE_CURRENT_BINARY_DIR}/${SUBMODULE_DIR}/${JSONFORTRAN}/include
	)

target_link_libraries(${PROJECT}
	${PNMIO}
	jsonfortran-static
	)

