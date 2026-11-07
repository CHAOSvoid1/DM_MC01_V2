# Normalize the CLion Debug profile before generated flags are evaluated.
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_BUILD_TYPE "debug_GCC_STM32C593RET6" CACHE STRING "MX2 configuration" FORCE)
    include("${CMAKE_SOURCE_DIR}/cmake/target.cmake")
    include("${CMAKE_SOURCE_DIR}/cmake/${TOOLCHAIN_FILE}")
endif()
# Loaded by CMake at the end of the top-level project() call.
# Defer target customization until generated targets have been created.
function(mx2_apply_user_configuration)
    include("${CMAKE_SOURCE_DIR}/cmake/user/Application.cmake")
endfunction()
cmake_language(DEFER CALL mx2_apply_user_configuration)
