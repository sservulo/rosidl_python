# Copyright 2018 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

find_package(rmw_implementation_cmake REQUIRED)
find_package(rmw REQUIRED)
find_package(rosidl_generator_c REQUIRED)
find_package(rosidl_typesupport_c REQUIRED)
find_package(rosidl_typesupport_interface REQUIRED)

find_package(PythonInterp 3.5 REQUIRED)

find_package(python_cmake_module REQUIRED)
find_package(PythonExtra MODULE REQUIRED)

# Get a list of typesupport implementations from valid rmw implementations.
rosidl_generator_py_get_typesupports(_typesupports)

if(_typesupports STREQUAL "")
  message(WARNING "No valid typesupport for Python generator. Python messages will not be generated.")
  return()
endif()

set(_output_path
  "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py/${PROJECT_NAME}")
set(_generated_files "")

foreach(_idl_file ${rosidl_generate_action_interfaces_IDL_FILES})
  get_filename_component(_extension "${_idl_file}" EXT)
  get_filename_component(_parent_folder "${_idl_file}" DIRECTORY)
  get_filename_component(_parent_folder "${_parent_folder}" NAME)
  if(_extension STREQUAL ".action")
    set(_allowed_parent_folders "action")
    if(NOT _parent_folder IN_LIST _allowed_parent_folders)
      message(FATAL_ERROR "Interface file with unknown parent folder: ${_idl_file}")
    endif()
  else()
    message(FATAL_ERROR "Interface file with unknown extension: ${_idl_file}")
  endif()
  get_filename_component(_msg_name "${_idl_file}" NAME_WE)
  string_camel_case_to_lower_case_underscore("${_msg_name}" _header_name)
  list(APPEND _generated_files
    "${_output_path}/${_parent_folder}/_${_module_name}_action.py"
  )
endforeach()

# python block
if(NOT _generated_files STREQUAL "")
  list(GET _generated_files 0 _action_file)
  get_filename_component(_parent_folder "${_action_file}" DIRECTORY)
  list(APPEND _generated_files
    "${_parent_folder}/__init__.py"
  )
endif()

set(_dependency_files "")
set(_dependencies "")
foreach(_pkg_name ${rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES})
  foreach(_idl_file ${${_pkg_name}_INTERFACE_FILES})
  get_filename_component(_extension "${_idl_file}" EXT)
  if(_extension STREQUAL ".msg")
    set(_abs_idl_file "${${_pkg_name}_DIR}/../${_idl_file}")
    normalize_path(_abs_idl_file "${_abs_idl_file}")
    list(APPEND _dependency_files "${_abs_idl_file}")
    list(APPEND _dependencies "${_pkg_name}:${_abs_idl_file}")
  endif()
  endforeach()
endforeach()

set(target_dependencies
  "${rosidl_generator_py_BIN}"
  ${rosidl_generator_py_GENERATOR_FILES}
  "${rosidl_generator_py_TEMPLATE_DIR}/_action.py.em"
  ${rosidl_generate_action_interfaces_IDL_FILES}
  ${_dependency_files})
foreach(dep ${target_dependencies})
  if(NOT EXISTS "${dep}")
    get_property(is_generated SOURCE "${dep}" PROPERTY GENERATED)
    if(NOT ${_is_generated})
      message(FATAL_ERROR "Target dependency '${dep}' does not exist")
    endif()
  endif()
endforeach()

set(generator_arguments_file
  "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py__generate_action_interfaces__arguments.json")
rosidl_write_generator_arguments(
  "${generator_arguments_file}"
  PACKAGE_NAME "${PROJECT_NAME}"
  ROS_INTERFACE_FILES "${rosidl_generate_action_interfaces_IDL_FILES}"
  ROS_INTERFACE_DEPENDENCIES "${_dependencies}"
  OUTPUT_DIR "${_output_path}"
  TEMPLATE_DIR "${rosidl_generator_py_TEMPLATE_DIR}"
  TARGET_DEPENDENCIES ${target_dependencies}
)

# get_used_typesupports(typesupports "rosidl_python")
add_custom_command(
  OUTPUT ${_generated_files}
  COMMAND ${PYTHON_EXECUTABLE} ${rosidl_generator_py_BIN}
  --generator-arguments-file "${generator_arguments_file}"
  --typesupports ${_typesupports}
  DEPENDS ${target_dependencies}
  COMMENT "Generating Python type support dispatch for ROS action interfaces"
  VERBATIM
)

set(_target_suffix "__rosidl_generator_py__generate_action_interfaces")

add_library(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
            ${rosidl_generator_py_LIBRARY_TYPE}
            ${_generated_files})
if(rosidl_generate_action_interfaces_LIBRARY_NAME)
  set_target_properties(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
    PROPERTIES OUTPUT_NAME "${rosidl_generate_action_interfaces_LIBRARY_NAME}${_target_suffix}")
endif()
target_compile_definitions(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
  PRIVATE "ROSIDL_GENERATOR_C_BUILDING_DLL_${PROJECT_NAME}_ACTION")

# set_target_properties(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   PROPERTIES CXX_STANDARD 14)
# if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
#   set_target_properties(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#     PROPERTIES COMPILE_OPTIONS -Wall -Wextra -Wpedantic)
# endif()
# target_include_directories(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   PUBLIC
#   ${CMAKE_CURRENT_BINARY_DIR}/rosidl_typesupport_c
# )
# target_link_libraries(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   ${rosidl_generate_action_interfaces_TARGET}__rosidl_generator_c)
# # Add dependency to type support library for generated msg and srv for actions
# target_link_libraries(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   ${rosidl_generate_action_interfaces_TARGET}__rosidl_typesupport_c)

# # if only a single typesupport is used this package will directly reference it
# # therefore it needs to link against the selected typesupport
# if(NOT typesupports MATCHES ";")
#   target_include_directories(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#     PUBLIC
#     "${CMAKE_CURRENT_BINARY_DIR}/${typesupports}")
#   target_link_libraries(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#     ${rosidl_generate_action_interfaces_TARGET}__${typesupports})
# else()
#   if("${rosidl_typesupport_c_LIBRARY_TYPE}" STREQUAL "STATIC")
#     message(FATAL_ERROR "Multiple typesupports but static linking was requested")
#   endif()
#   if(NOT rosidl_typesupport_c_SUPPORTS_POCO)
#     message(FATAL_ERROR "Multiple typesupports but Poco was not available when "
#       "rosidl_typesupport_c was built")
#   endif()
# endif()

# ament_target_dependencies(${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   "rosidl_generator_c"
#   "rosidl_typesupport_c"
#   "rosidl_typesupport_interface")
# foreach(_pkg_name ${rosidl_generate_action_interfaces_DEPENDENCY_PACKAGE_NAMES})
#   ament_target_dependencies(
#     ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#     ${_pkg_name})
# endforeach()

# add_dependencies(
#   ${rosidl_generate_action_interfaces_TARGET}
#   ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
# )
# # Depend on generated headers for C type support
# add_dependencies(
#   ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#   ${rosidl_generate_action_interfaces_TARGET}__c__actions
# )

# if(NOT rosidl_generate_action_interfaces_SKIP_INSTALL)
#   install(
#     TARGETS ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
#     ARCHIVE DESTINATION lib
#     LIBRARY DESTINATION lib
#     RUNTIME DESTINATION bin
#   )
#   ament_export_libraries(${rosidl_generate_action_interfaces_TARGET}${_target_suffix})
# endif()

# python block
set(_target_suffix "_actions__py")

# move custom command into a subdirectory to avoid multiple invocations on Windows
set(_subdir
  "${CMAKE_CURRENT_BINARY_DIR}/${rosidl_generate_action_interfaces_TARGET}${_target_suffix}")
file(MAKE_DIRECTORY "${_subdir}")
# TODO: custom cmake?
file(READ "${rosidl_generator_py_DIR}/custom_command.cmake" _custom_command)
file(WRITE "${_subdir}/CMakeLists.txt" "${_custom_command}")
add_subdirectory("${_subdir}" ${rosidl_generate_action_interfaces_TARGET}${_target_suffix})
set_property(
  SOURCE
  ${_generated_files}
  PROPERTY GENERATED 1)

macro(set_properties _build_type)
  set_target_properties(${_target_name} PROPERTIES
    COMPILE_OPTIONS "${_extension_compile_flags}"
    PREFIX ""
    LIBRARY_OUTPUT_DIRECTORY${_build_type} ${_output_path}
    RUNTIME_OUTPUT_DIRECTORY${_build_type} ${_output_path}
    OUTPUT_NAME "${PROJECT_NAME}_s__${_typesupports}${PythonExtra_EXTENSION_SUFFIX}"
    SUFFIX "${PythonExtra_EXTENSION_EXTENSION}")
endmacro()

macro(set_lib_properties _build_type)
  set_target_properties(${_target_name_lib} PROPERTIES
    COMPILE_OPTIONS "${_extension_compile_flags}"
    LIBRARY_OUTPUT_DIRECTORY${_build_type} ${_output_path}
    RUNTIME_OUTPUT_DIRECTORY${_build_type} ${_output_path})
endmacro()

set(_target_name_lib "${rosidl_generate_action_interfaces_TARGET}__actions_python")
add_library(${_target_name_lib} SHARED
  ${_generated_files}
)
add_dependencies(
  ${_target_name_lib}
  ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
  ${rosidl_generate_action_interfaces_TARGET}__rosidl_typesupport_c
)

target_link_libraries(
  ${_target_name_lib}
  ${PythonExtra_LIBRARIES}
)
target_include_directories(${_target_name_lib}
  PUBLIC
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_c
  ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py
  ${PythonExtra_INCLUDE_DIRS}
)

rosidl_target_interfaces(${_target_name_lib}
  ${rosidl_generate_action_interfaces_TARGET} rosidl_typesupport_c)

foreach(_typesupport_impl ${_typesupports})
  find_package(${_typesupport_impl} REQUIRED)

  set(_pyext_suffix "__pyext")
  set(_target_name "${PROJECT_NAME}__${_typesupport_impl}${_pyext_suffix}")

  # TODO: extension?
  add_library(${_target_name} SHARED
    ${_generated_extension_${_typesupport_impl}_files}
  )
  add_dependencies(
    ${_target_name}
    ${rosidl_generate_action_interfaces_TARGET}${_target_suffix}
    ${rosidl_generate_action_interfaces_TARGET}__rosidl_typesupport_c
  )

  set(_extension_compile_flags "")
  set(_PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE})
  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(_extension_compile_flags -Wall -Wextra)
  endif()
  if(WIN32 AND "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
    set(PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE_DEBUG})
  endif()
  set_properties("")
  if(WIN32)
    set_properties("_DEBUG")
    set_properties("_MINSIZEREL")
    set_properties("_RELEASE")
    set_properties("_RELWITHDEBINFO")
  endif()
  target_link_libraries(
    ${_target_name}
    ${_target_name_lib}
    ${PythonExtra_LIBRARIES}
    ${rosidl_generate_action_interfaces_TARGET}__${_typesupport_impl}
  )

  target_include_directories(${_target_name}
    PUBLIC
    ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_c
    ${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py
    ${PythonExtra_INCLUDE_DIRS}
  )

  rosidl_target_interfaces(${_target_name}
    ${rosidl_generate_action_interfaces_TARGET} rosidl_typesupport_c)

  ament_target_dependencies(${_target_name}
    "rosidl_generator_c"
    "rosidl_typesupport_c"
    "rosidl_typesupport_interface"
  )
  foreach(_pkg_name ${rosidl_generate_action_interfaces_DEPENDENCY_PACKAGE_NAMES})
    ament_target_dependencies(${_target_name}
      ${_pkg_name}
    )
  endforeach()

  add_dependencies(${_target_name}
    ${rosidl_generate_action_interfaces_TARGET}__${_typesupport_impl}
  )
  ament_target_dependencies(${_target_name}
    "rosidl_generator_c"
    "rosidl_generator_py"
    "${rosidl_generate_action_interfaces_TARGET}__rosidl_generator_c"
  )
  set(PYTHON_EXECUTABLE ${_PYTHON_EXECUTABLE})

  if(NOT rosidl_generate_action_interfaces_SKIP_INSTALL)
    install(TARGETS ${_target_name}
      DESTINATION "${PYTHON_INSTALL_DIR}/${PROJECT_NAME}")
  endif()
endforeach()

foreach(_pkg_name ${rosidl_generate_action_interfaces_DEPENDENCY_PACKAGE_NAMES})
  set(_pkg_install_base "${${_pkg_name}_DIR}/../../..")
  set(_pkg_python_libname "${_pkg_name}__python")

  if(WIN32)
    target_link_libraries(${_target_name_lib} "${_pkg_install_base}/Lib/${_pkg_python_libname}.lib")
  elseif(APPLE)
    target_link_libraries(${_target_name_lib} "${_pkg_install_base}/lib/lib${_pkg_python_libname}.dylib")
  else()
    target_link_libraries(${_target_name_lib} "${_pkg_install_base}/lib/lib${_pkg_python_libname}.so")
  endif()
endforeach()

set_lib_properties("")
if(WIN32)
  set_lib_properties("_DEBUG")
  set_lib_properties("_MINSIZEREL")
  set_lib_properties("_RELEASE")
  set_lib_properties("_RELWITHDEBINFO")
endif()
if(NOT rosidl_generate_interfaces_SKIP_INSTALL)
  install(TARGETS ${_target_name_lib}
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin)
endif()

# lint checks
if(BUILD_TESTING AND rosidl_generate_interfaces_ADD_LINTER_TESTS)
  if(NOT _generatedfiles STREQUAL "")
    # c tests?
    find_package(ament_cmake_cppcheck REQUIRED)
    ament_cppcheck(
      TESTNAME "cppcheck_rosidl_generated_action_interfaces_py"
      "${_output_path}")

    find_package(ament_cmake_cpplint REQUIRED)
    get_filename_component(_cpplint_root "${_output_path}" DIRECTORY)
    ament_cpplint(
      TESTNAME "cpplint_rosidl_generated_action_interfaces_py"
      # the generated code might contain functions with more lines
      FILTERS "-readability/fn_size"
      # the generated code might contain longer lines for templated types
      MAX_LINE_LENGTH 999
      ROOT "${_cpplint_root}"
      "${_output_path}")

    find_package(ament_cmake_flake8 REQUIRED)
    ament_flake8(
      TESTNAME "flake8_rosidl_generated_action_interfaces_py"
      # the generated code might contain longer lines for templated types
      MAX_LINE_LENGTH 999
      "${_output_path}")

    find_package(ament_cmake_pep257 REQUIRED)
    ament_pep257(
      TESTNAME "pep257_rosidl_generated_action_interfaces_py"
      "${_output_path}")

    find_package(ament_cmake_uncrustify REQUIRED)
    ament_uncrustify(
      TESTNAME "uncrustify_rosidl_generated_action_interfaces_py"
      # the generated code might contain longer lines for templated types
      MAX_LINE_LENGTH 999
      "${_output_path}")
  endif()
endif()
