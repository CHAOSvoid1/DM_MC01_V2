# file-format: 1.0.0
cmake_minimum_required(VERSION 3.20)

set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_FORCED TRUE)

# ---------------------------------------------------------------------------
# 兼容处理：CLion 里如果不是用 CMakePresets（而是手工建的 profile），就不会传
# TOOLCHAIN_FILE，也不会传正确的 build type，于是生成文件里的条件分支全部不成立。
# 这里补默认值，保证"用 preset"和"用手工 profile"两条路都能编。
# ---------------------------------------------------------------------------
if(NOT DEFINED TOOLCHAIN_FILE OR "${TOOLCHAIN_FILE}" STREQUAL "")
  set(TOOLCHAIN_FILE "GCC.14.3.1.cmake")
endif()

if(NOT CMAKE_BUILD_TYPE STREQUAL "debug_GCC_STM32C593RET6")
  message(STATUS "MX2: build type '${CMAKE_BUILD_TYPE}' -> debug_GCC_STM32C593RET6")
  set(CMAKE_BUILD_TYPE "debug_GCC_STM32C593RET6" CACHE STRING "MX2 build type" FORCE)
endif()

include(cmake/target.cmake)
include(cmake/${TOOLCHAIN_FILE})

# 工具链目录（GCC 13.3.1）。存在就强制使用，避免 CMakeCache 里残留的失效编译器路径。
set(MX2_ARM_GCC_BIN "C:/CLionToolchains/DevEnv/GNU-tools-for-STM32/bin" CACHE PATH "MX2 arm-none-eabi bin dir")
if(EXISTS "${MX2_ARM_GCC_BIN}/arm-none-eabi-gcc.exe")
  set(CMAKE_C_COMPILER   "${MX2_ARM_GCC_BIN}/arm-none-eabi-gcc.exe"   CACHE FILEPATH "MX2 C compiler"   FORCE)
  if(EXISTS "${MX2_ARM_GCC_BIN}/arm-none-eabi-g++.exe")
    set(CMAKE_CXX_COMPILER "${MX2_ARM_GCC_BIN}/arm-none-eabi-g++.exe" CACHE FILEPATH "MX2 CXX compiler" FORCE)
  endif()
  set(ENV{PATH} "${MX2_ARM_GCC_BIN};$ENV{PATH}")
endif()

project(DM_MC01_V2)
add_executable(DM_MC01_V2)
include(cmake/files.cmake)
include(cmake/flags.cmake)
include(cmake/components.cmake)

# Stubs to be able to add compiler flag overrides, e.g. -Os
#
# ---------------------------------------------------------------------------
# 用户代码区（仿 C_Board_v1.0 的 User_Files 布局）
# 本文件属于 CubeMX2 的 "project_file"，重新生成代码时不会被覆盖；
# cmake/files.cmake、cmake/flags.cmake 属于 generated，每次生成都会被重写，不要往里加东西。
# 规则：User_Files/ 下任意层级的 .c/.cpp/.s 自动参与编译，.h 所在目录自动加入 include。
# ---------------------------------------------------------------------------
set(MX2_USER_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/User_Files)

set(MX2_USER_SOURCES "")
set(MX2_USER_INCLUDE_DIRS ${MX2_USER_FILES_DIR})

if(EXISTS ${MX2_USER_FILES_DIR})
  file(GLOB_RECURSE MX2_USER_SOURCES CONFIGURE_DEPENDS
    ${MX2_USER_FILES_DIR}/*.c
    ${MX2_USER_FILES_DIR}/*.cpp
    ${MX2_USER_FILES_DIR}/*.s
    ${MX2_USER_FILES_DIR}/*.S
  )
  file(GLOB_RECURSE MX2_USER_HEADERS CONFIGURE_DEPENDS
    ${MX2_USER_FILES_DIR}/*.h
    ${MX2_USER_FILES_DIR}/*.hpp
  )
  foreach(_mx2_header IN LISTS MX2_USER_HEADERS)
    get_filename_component(_mx2_header_dir "${_mx2_header}" DIRECTORY)
    list(APPEND MX2_USER_INCLUDE_DIRS "${_mx2_header_dir}")
  endforeach()
  list(REMOVE_DUPLICATES MX2_USER_INCLUDE_DIRS)
  list(LENGTH MX2_USER_SOURCES _mx2_user_source_count)
  message(STATUS "MX2 user sources: ${_mx2_user_source_count} file(s) under ${MX2_USER_FILES_DIR}")
endif()

target_sources(${CMAKE_PROJECT_NAME} PRIVATE
  # Add additional source files here
  ${MX2_USER_SOURCES}
)

target_include_directories(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional include directories here
  ${MX2_USER_INCLUDE_DIRS}
)

target_compile_definitions(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional defined symbols here
)

target_compile_options(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional compiler flags here
)

target_link_options(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional linker flags here
  # newlib-nano 默认裁剪了浮点 printf，加这个才支持 printf("%f", x)
  -u _printf_float
  # 链接结束打印 FLASH/RAM 占用，方便盯大小
  -Wl,--print-memory-usage
)

target_link_directories(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional linker search directories here
)

target_link_libraries(${CMAKE_PROJECT_NAME} PUBLIC
  # Add additional linker libraries here
)
