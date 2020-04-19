
cmake_minimum_required(VERSION 3.7)

set(PROJECT life)

if (LINUX)
	set(CMAKE_Fortran_FLAGS "-Wall -Wextra -fopenmp")
	set(CMAKE_Fortran_FLAGS_DEBUG "-pedantic -fbounds-check -fbacktrace")
	set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
elseif (APPLE)
else()
	# Windows
	set(CMAKE_Fortran_FLAGS "-Wall -Wextra -fopenmp")
	set(CMAKE_Fortran_FLAGS_DEBUG "-pedantic -fbounds-check -fbacktrace")
	set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
endif()

set(CMAKE_Fortran_COMPILER "gfortran")

project(${PROJECT} Fortran)

#set(PNMIO pnmio)
#add_subdirectory(${PNMIO})

add_executable(${PROJECT} life.f ${PNMIO})

#include_directories(${CMAKE_CURRENT_BINARY_DIR}/${PNMIO})
#target_link_libraries(${PROJECT} ${PNMIO})

