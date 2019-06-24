cmake_minimum_required(VERSION 3.0)
project(MetalTextureFastLoad)

set(ROOT_PATH "${PROJECT_SOURCE_DIR}")
set(SAMPLE_NAME ${PROJECT_NAME})

include_directories(${glfw_INCLUDE_DIRS} "${GLFW_SOURCE_DIR}/deps")

set(GLFW_BUILD_DOCS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(GLFW_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GLFW_INSTALL OFF CACHE BOOL "" FORCE)

add_subdirectory(glfw)

include_directories(${ROOT_PATH})
include_directories(${ROOT_PATH}/glfw/deps)
include_directories(${ROOT_PATH}/glfw/include)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-D_CRT_SECURE_NO_WARNINGS)

file(GLOB HEADER_LIST *.h *.hpp)
file(GLOB SOURCE_LIST *.cpp *.mm)
source_group("sources" FILES ${HEADER_LIST} ${SOURCE_LIST})

add_executable(${SAMPLE_NAME} ${HEADER_LIST} ${SOURCE_LIST} ${SHADERS})

target_link_libraries(${SAMPLE_NAME} PRIVATE glfw)
target_link_libraries(${SAMPLE_NAME} PRIVATE "-framework AppKit")
target_link_libraries(${SAMPLE_NAME} PRIVATE "-framework Metal")
target_link_libraries(${SAMPLE_NAME} PRIVATE "-framework QuartzCore")
