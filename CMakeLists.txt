
cmake_minimum_required(VERSION 3.7)

set(PROJECT life)

set(CMAKE_Fortran_FLAGS "-Wall -Wextra -fopenmp -Wno-tabs")
set(CMAKE_Fortran_FLAGS_DEBUG "-pedantic -fbounds-check -fbacktrace")
set(CMAKE_Fortran_FLAGS_RELEASE "-O3")

if(APPLE)
	set(CMAKE_EXE_LINKER_FLAGS "-openmp")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else()
	set(CMAKE_EXE_LINKER_FLAGS "-fopenmp")
endif()

set(CMAKE_Fortran_COMPILER "gfortran")


project(${PROJECT} Fortran CXX)

set(SUBMODULE_DIR submodules)

set(PNMIO pnmio)
set(JSONFORTRAN json-fortran)
set(COLORMAPPER colormapper)

add_subdirectory(${SUBMODULE_DIR}/${PNMIO})
add_subdirectory(${SUBMODULE_DIR}/${JSONFORTRAN})
add_subdirectory(${SUBMODULE_DIR}/${COLORMAPPER})

add_executable(${PROJECT} life.f90 colormapper_wrapper.cpp)

# TODO:  pnmio's include directory could be automatically targetted like colormapper's?
include_directories(
	${SUBMODULE_DIR}/${COLORMAPPER}
	${CMAKE_CURRENT_BINARY_DIR}/${SUBMODULE_DIR}/${PNMIO}
	${CMAKE_CURRENT_BINARY_DIR}/${SUBMODULE_DIR}/${JSONFORTRAN}/include
	)

target_link_libraries(${PROJECT}
	${PNMIO}
	jsonfortran-static
	${COLORMAPPER}
	)

