# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

factory = ->
  class Form
    constructor: (@_element, @_formlets) ->

    element: ->
      ###
      Return the form element attached to this form.
      ###
      @_element

    formlets: ->
      ###
      Return the formlets that make up this form.
      ###
      @_formlets

    validate: ->
      ###
      Validate all of the formlets on this form and return the validation
      results.
      ###
      results = (fl.validate() for fl in @_formlets)
      results = results.filter (r) -> r.length > 0
      [].concat.apply([], results)

  class Formlet
    constructor: (@_formletType, @_element, @_fields, @_childFormlets) ->
      ###
      Construct a new formlet instance.

      @param {string} _type - String representation of the type of this
        formlet, e.g. 'Formlet.Formlet'.
      @param {HTMLElement} _element - Element associated with this formlet.
      @param {Field[]} _fields - Fields attached to this formlet.
      @param {Formlet[]} _childFormlets - Child formlets attached
        to this formlet.
      ###

    element: ->
      @_element

    validate: ->
      # Validate the child formlets and fields and collect the results.
      validationResults = [].concat.apply(
        []
        , fl.validate() for fl in @_childFormlets
        )
      validationResults = validationResults.concat.apply(
        []
        , f.validate() for f in @_fields
        )

      validationResults

    formletType: ->
      @_formletType

  class Field
    constructor: (@_fieldType, @_element, @_validators) ->
      ###
      Construct a new field instance.

      @param {string} type - Type of input element that this field wraps; may
        be one of Field.fieldTypes().
      @param {object[]} element - Element associated with this field.
      @param {FieldValidator[]} validators - List of field validators used to
        validate this field.
      ###

    element: ->
      @_element

    fieldType: ->
      @_fieldType

    validate: ->
      results = (v.validateField(this) for v in @_validators)

  class TextField extends Field
    @fieldType: ->
      'Text'

    constructor: (element, validators, @_inputElement) ->
      super TextField.fieldType(), element, validators

    inputElement: ->
      @_inputElement

  class OptionField extends Field
    @fieldType: ->
      'Option'

    constructor: (element, validators, @_optionElements) ->
      super OptionField.fieldType(), element, validators

    optionElements: ->
      @_optionElements

  class ValidationResult
    constructor: (@_target, @_isValid, @_message = null) ->

    target: ->
      @_target

    isValid: ->
      @_isValid

    message: ->
      @_message

  class FieldValidator
    fieldValidatorType: ->
      @_fieldValidatorType

    constructor: (\
        @_fieldValidatorType
        , @_acceptedFieldTypes = Field.fieldTypes()
        ) ->

    validateField: (field) ->
      if field.fieldType() not in @_acceptedFieldTypes
        throw new Error(
          """
          Field of type '#{field.fieldType()}' is not supported by this
          validator
          """
          )

  class Plugin
    constructor: (\
        @_name
        , @_extensionMethods = {}
        , @_formletClasses = []
        , @_fieldValidatorClasses = []
        ) ->

    name: ->
      @_name

    extensionMethods: ->
      @_extensionMethods

    formletClasses: ->
      @_formletClasses

    fieldValidatorClasses: ->
      @_fieldValidatorClasses

  definition =
    Form: Form
    Formlet: Formlet
    Field: Field
    ValidationResult: ValidationResult
    FieldValidator: FieldValidator
    Plugin: Plugin

    _fieldClasses: {}
    _formletClasses: {}
    _fieldValidatorClasses: {}
    _plugins: {}

    constructField: (fieldType, element, validators, args...) ->
      unless fieldType of @_fieldClasses
        throw new Error("Unknown field type '#{fieldType}'")
      new @_fieldClasses[fieldType](element, validators, args...)

    constructFormlet: (formletType, element, fields, childFormlets, options) ->
      unless formletType of @_formletClasses
        throw new Error("No registered formlet class for '#{formletType}'")
      new @_formletClasses[formletType](
        element
        , fields
        , childFormlets
        , options
        )

    constructFieldValidator: (fieldValidatorType, args...) ->
      unless fieldValidatorType of @_fieldValidatorClasses
        throw new Error(
          """
          No registered field validator class for '#{fieldValidatorType}'
          """
          )
      new @_fieldValidatorClasses[fieldValidatorType](args...)

    registerPlugin: (plugin) ->
      pluginName = plugin.name()
      if pluginName of @_plugins
        throw new Error(
          """
          Plugin with name '#{pluginName}' is already registered
          """
          )
      @_plugins[pluginName] = plugin
      @_registerExtensionMethod(m) for m in plugin.extensionMethods()
      @_registerFormletClass(f) for f in plugin.formletClasses()
      @_registerFieldValidatorClass(fv) for fv in \
        plugin.fieldValidatorClasses()

    utils:
      extend: ->
        result = {}
        for arg in arguments
          result[key] = val for key, val of arg when arg.hasOwnProperty(key)
        result

    _registerExtensionMethod: (methodName, method) ->
      if methodName of this
        throw new Error(
          """
          Formlet plugin extension method '#{methodName}' for plugin
          '#{plugin.name()}' would overwrite existing method
          """
          )
      @[methodName] = method.bind this

    _registerFieldClass: (fieldClass) ->
      fieldType = fieldClass.fieldType()
      if fieldType of @_fieldClasses
        throw new Error("Field type '#{fieldType}' is already registered")
      @_fieldClasses[fieldType] = fieldClass

    _registerFormletClass: (formletClass) ->
      formletType = formletClass.formletType()
      if formletType of @_formletClasses
        throw new Error(
          """
          Formlet type '#{formletType}' is already registered
          """
          )
      @_formletClasses[formletType] = formletClass

    _registerFieldValidatorClass: (fieldValidatorClass) ->
      fieldValidatorType = fieldValidatorClass.fieldValidatorType()
      if fieldValidatorType of @_fieldValidatorClasses
        throw new Error(
          """
          Field validator type '#{fieldValidatorType}' is already registered
          """
          )
      @_fieldValidatorClasses[fieldValidatorType] = fieldValidatorClass

  definition._registerFieldClass(TextField)
  definition._registerFieldClass(OptionField)

  definition

do (root = this, factory) ->
  if (typeof define == 'function') and define.amd
    # AMD. Register as an anonymous module.
    define [], ->
      root.formlet = factory()
  else if typeof exports == 'object'
    # Node. Does not work with strict CommonJS, but
    # only CommonJS-like enviroments that support module.exports,
    # like Node.
    module.exports = factory()
  else
    # Browser globals
    root.formlet = factory()
