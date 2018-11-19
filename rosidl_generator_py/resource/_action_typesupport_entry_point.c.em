// generated from rosidl_generator_py/resource/_msg_pkg_typesupport_entry_point.c.em
// generated code does not contain a copyright notice

@#######################################################################
@# EmPy template for generating _<msg_pkg>_s.ep.<typesupport_impl>_c.c files
@#
@# Context:
@#  - package_name
@#  - action_specs (list of rosidl_parser.ActionSpecification)
@#    Parsed specification of the .action files
@#  - typesupport_impl (string identifying the typesupport used)
@#  - convert_camel_case_to_lower_case_underscore (function)
@#######################################################################
@
#include <Python.h>
#include <stdbool.h>
#include <stdint.h>

@{
static_includes = set([
    '#include <rosidl_generator_c/message_type_support_struct.h>',
    '#include <rosidl_generator_c/visibility_control.h>',
])
}@
@[for value in sorted(static_includes)]@
@(value)
@[end for]@

static PyMethodDef @(package_name)__methods[] = {
  {NULL, NULL, 0, NULL}  /* sentinel */
};

static struct PyModuleDef @(package_name)__module = {
  PyModuleDef_HEAD_INIT,
  "_@(package_name)_support",
  "_@(package_name)_doc",
  -1,  /* -1 means that the module keeps state in global variables */
  @(package_name)__methods,
  NULL,
  NULL,
  NULL,
  NULL,
};

@[for spec, subfolder in action_specs]@
@{
type_name = convert_camel_case_to_lower_case_underscore(spec.action_name)
function_name = 'type_support'
}@

ROSIDL_GENERATOR_C_IMPORT
const rosidl_action_type_support_t *
ROSIDL_TYPESUPPORT_INTERFACE__ACTION_SYMBOL_NAME(rosidl_typesupport_c, @(spec.pkg_name), @(subfolder), @(spec.action_name))();

int8_t
_register_action_type__@(subfolder)__@(type_name)(PyObject * pymodule)
{
  int8_t err;
  PyObject * pyobject_@(function_name) = NULL;
  pyobject_@(function_name) = PyCapsule_New(
    (void *)ROSIDL_TYPESUPPORT_INTERFACE__ACTION_SYMBOL_NAME(rosidl_typesupport_c, @(spec.pkg_name), @(subfolder), @(spec.action_name))(),
    NULL, NULL);
  if (!pyobject_@(function_name)) {
    // previously added objects will be removed when the module is destroyed
    return -1;
  }
  err = PyModule_AddObject(
    pymodule,
    "@(function_name)_action__@(subfolder)_@(type_name)",
    pyobject_@(function_name));
  if (err) {
    // the created capsule needs to be decremented
    Py_XDECREF(pyobject_@(function_name));
    // previously added objects will be removed when the module is destroyed
    return err;
  }
  return 0;
}
@[end for]@

PyMODINIT_FUNC
PyInit_@(package_name)_s__@(typesupport_impl)(void)
{
  PyObject * pymodule = NULL;
  pymodule = PyModule_Create(&@(package_name)__module);
  if (!pymodule) {
    return NULL;
  }
  int8_t err;
@[for spec, subfolder in action_specs]@
@{
type_name = convert_camel_case_to_lower_case_underscore(spec.action_name)
}@
  err = _register_action_type__@(subfolder)__@(type_name)(pymodule);
  if (err) {
    Py_XDECREF(pymodule);
    return NULL;
  }
@[end for]@

  return pymodule;
}
