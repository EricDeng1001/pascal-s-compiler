cmake_minimum_required(VERSION 3.10)
project(SymbolTable)

set(CMAKE_CXX_STANDARD 17)
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -Wall")

find_package(GTest REQUIRED)
find_package(Threads REQUIRED)

include_directories(${GTEST_INCLUDE_DIRS})

add_executable(Tests test.cc)

target_link_libraries(Tests ${GTEST_BOTH_LIBRARIES})
target_link_libraries(Tests ${CMAKE_THREAD_LIBS_INIT})

add_test(Test Tests)
enable_testing()