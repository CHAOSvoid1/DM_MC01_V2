# User-owned application sources and link options.
file(GLOB_RECURSE user_sources CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.c"
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.cpp"
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.s"
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.S"
)
file(GLOB_RECURSE user_headers CONFIGURE_DEPENDS
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.h"
    "${CMAKE_CURRENT_LIST_DIR}/../../User_Files/*.hpp"
)
set(user_include_dirs "${CMAKE_CURRENT_LIST_DIR}/../../User_Files")
foreach(header IN LISTS user_headers)
    get_filename_component(header_dir "${header}" DIRECTORY)
    list(APPEND user_include_dirs "${header_dir}")
endforeach()
list(REMOVE_DUPLICATES user_include_dirs)
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${user_sources})
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${user_include_dirs})


# MX2 1.2 can emit an empty trigger enum for the selected software trigger.
# Correct only this exact invalid assignment; valid trigger selections are preserved.
foreach(adc IN ITEMS adc1 adc2)
    set(adc_file "${CMAKE_SOURCE_DIR}/generated/hal/mx_${adc}.c")
    if(EXISTS "${adc_file}")
        file(READ "${adc_file}" adc_source)
        string(REPLACE "= HAL_ADC_REG_TRIG_;" "= HAL_ADC_REG_TRIG_SOFTWARE;" adc_fixed "${adc_source}")
        if(NOT adc_source STREQUAL adc_fixed)
            file(WRITE "${adc_file}" "${adc_fixed}")
            message(STATUS "Corrected MX2 empty software trigger in ${adc}")
        endif()
    endif()
endforeach()