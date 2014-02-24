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
    @_registeredFormletTypes: {}

    @registeredFormletTypes: =>
      copy = {}
      for ft, ts of @_regiseredFormletTypes
        copy.set ts, ft
      copy

    @registerFormletType: (typeString, formletType) =>
      @_registeredFormletTypes[typeString] = formletType

    @formletType: (typeString) =>
      @_registeredFormletTypes[typeString]

    constructor: (@_type, @_element, @_fields, @_childFormlets) ->
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

    type: ->
      @_type

  class OptionsWithOtherFormlet extends Formlet
    constructor: (\
        element
        , @_optionField
        , @_otherField
        , @_message = 'Please select an option or enter another value'
        ) ->
      fields = [@_optionField, @_otherField]
      super 'OptionsWithOther', element, fields, []

    validate: ->
      checkedOptions = (
        opt for opt in @_optionField.optionElements() when opt.checked)
      otherValue = @_otherField.inputElement().value.trim()

      isOptionChecked = checkedOptions.length > 0
      isOtherFilled = otherValue != ''
      isValid = (isOptionChecked and !isOtherFilled) or
                (!isOptionChecked and isOtherFilled)
      message = if isValid then null else @_message
      result = new ValidationResult(@element(), isValid, message)

      # Only run additional validators on the other field if it is filled.
      results = if isValid && isOtherFilled then super().concat [result] else
        [result]

  class Field
    @_fieldTypes: {}

    @fieldTypes: =>
      @_fieldTypes

    @registerFieldType: (typeString, fieldType) =>
      @_fieldTypes[typeString] = fieldType

    constructor: (@_fieldType, @_element, @_validators) ->
      ###
      Construct a new field instance.

      @param {string} type - Type of input element that this field wraps; may
        be one of Field.fieldTypes().
      @param {object[]} element - Element associated with this field.
      @param {FieldValidator[]} validators - List of field validators used to
        validate this field.
      ###

    fieldType: ->
      @_fieldType

    element: ->
      @_element

    validate: ->
      results = (v.validateField(this) for v in @_validators)

  class TextField extends Field
    @fieldType: ->
      'text'

    constructor: (element, @_inputElement, validators) ->
      super TextField.fieldType(), element, validators

    inputElement: ->
      @_inputElement
  Field.registerFieldType TextField.fieldType(), TextField

  class OptionField extends Field
    @fieldType: ->
      'option'

    constructor: (element, @_optionElements, validators) ->
      super OptionField.fieldType(), element, validators

    optionElements: ->
      @_optionElements
  Field.registerFieldType OptionField.fieldType(), OptionField

  class ValidationResult
    constructor: (@_target, @_isValid, @_message = null) ->

    target: ->
      @_target

    isValid: ->
      @_isValid

    message: ->
      @_message

  class FieldValidator
    constructor: (acceptedFieldTypes) ->
      @_acceptedFieldTypes = acceptedFieldTypes || Field.fieldTypes()

    validateField: (field) ->
      if field.fieldType() not in @_acceptedFieldTypes
        throw new Error(
          "Field of type #{field.fieldType()} is not supported by this " +
          'validator'
          )

  class RequiredFieldValidator extends FieldValidator
    constructor: (\
        @_emptyValue = ''
        , @_message = 'This field is required'
        ) ->
      super ['text', 'radio', 'select']

    validateField: (field) ->
      super field

      element = field.element()
      value = element.value.trim()
      isEmpty = false
      if @_emptyValue instanceof RegExp
        isEmpty = @_emptyValue.test value
      else
        isEmpty = value == @_emptyValue

      new ValidationResult(element, !isEmpty, @_message)

  class RegexFieldValidator extends FieldValidator
    constructor: (\
        @_regexp
        , @_message = 'Field does not match expected pattern'
        ) ->
      super ['text']

    validateField: (field) ->
      super field

      inputElement = field.inputElement()
      value = inputElement.value.trim()
      isValid = @_regexp.test value
      message = if isValid then null else @_message

      new ValidationResult(field.element(), isValid, message)

  return {
    Form: Form
    Formlet: Formlet
    OptionsWithOtherFormlet: OptionsWithOtherFormlet
    Field: Field
    TextField: TextField
    OptionField: OptionField
    ValidationResult: ValidationResult
    FieldValidator: FieldValidator
    RequiredFieldValidator: RequiredFieldValidator
    RegexFieldValidator: RegexFieldValidator
  }

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
