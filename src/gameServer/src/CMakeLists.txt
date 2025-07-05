

cmake_minimum_required(VERSION 3.0)


SET(CMAKE_CXX_COMPILER "/opt/rh/devtoolset-9/root/bin/g++")
SET(CMAKE_CC_COMPILER "/opt/rh/devtoolset-9/root/bin/gcc")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -Wall -O0 -rdynamic")
set(CMAKE_CXX_STANDARD 17)
set (process_name "wxgame") 
project(${process_name})

execute_process(COMMAND test -e ${PROJECT_SOURCE_DIR}/../build/build_number RESULT_VARIABLE file_exists)
if (NOT ${file_exists} EQUAL 0)
    execute_process(COMMAND sh -c "echo 1 > ${PROJECT_SOURCE_DIR}/../build/build_number ")
endif()

string(TIMESTAMP BUILD_TIME "%Y%m%d")
file(READ ${PROJECT_SOURCE_DIR}/../build/build_number BUILD_NUMBER)
math(EXPR BUILD_NUMBER "${BUILD_NUMBER}+1")
file(WRITE ${PROJECT_SOURCE_DIR}/../build/build_number ${BUILD_NUMBER})


file(GLOB_RECURSE SOURCES  src/*.h *.cpp *.hpp *.cc)
file(GLOB_RECURSE COMMON_SOURCES 
"${CMAKE_CURRENT_SOURCE_DIR}/../../common/*.cpp" 
"${CMAKE_CURRENT_SOURCE_DIR}/../../common/*.hpp" 
"${CMAKE_CURRENT_SOURCE_DIR}/../../common/*.h"
"${CMAKE_CURRENT_SOURCE_DIR}/../../common/*.cc"
"${CMAKE_CURRENT_SOURCE_DIR}/../../common/*.c"
)


# list(REMOVE_ITEM COMMON_SOURCES 
# "${CMAKE_CURRENT_SOURCE_DIR}/../../common/pb/Player.pb."
# "${CMAKE_CURRENT_SOURCE_DIR}/../../common/pb/Player.pb.cc"
# )


SET(EXECUTABLE_OUTPUT_PATH ../bin) #设置exe的输出路径 PROJECT_SOURCE_DIR cmake path 相对于build路径
include_directories(../../../libs) 
link_directories(../../../libs) 





add_executable(game ${COMMON_SOURCES} ${SOURCES} ${COMMON_SOURCES})
target_link_libraries(game lua mysqlcppconn ssl crypto pthread protobuf readline tinfo)








