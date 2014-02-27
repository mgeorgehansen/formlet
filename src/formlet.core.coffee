# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

factory = (formlet) ->
  class OptionsWithOtherFormlet extends formlet.Formlet
    @formletType: ->
      'OptionsWithOther'

    @defaultOptions: ->
      message: "Please select an option or enter another value"

    constructor: (element, fields, childFormlets, options = {}) ->
      @_optionField = (f for f in fields when f.fieldType() == 'Option').pop()
      @_otherField = (f for f in fields when f.fieldType() == 'Text').pop()
      opts = formlet.utils.extend(
        options
        , OptionsWithOtherFormlet.defaultOptions()
        )
      @_message = opts.message
      super(
        OptionsWithOtherFormlet.formletType()
        , element
        , fields
        , childFormlets
        )

    validate: ->
      checkedOptions = (
        opt for opt in @_optionField.optionElements() when opt.checked)
      otherValue = @_otherField.inputElement().value.trim()

      isOptionChecked = checkedOptions.length > 0
      isOtherFilled = otherValue != ''
      isValid = (isOptionChecked and !isOtherFilled) or
                (!isOptionChecked and isOtherFilled)
      message = if isValid then null else @_message
      result = new formlet.ValidationResult(@element(), isValid, message)

      # Only run additional validators on the other field if it is filled.
      results = if isValid && isOtherFilled then super().concat [result] else
        [result]

  class RequiredFieldValidator extends formlet.FieldValidator
    @fieldValidatorType: ->
      'Required'

    constructor: (\
        @_emptyValue = ''
        , @_message = 'This field is required'
        ) ->
      super RequiredFieldValidator.fieldValidatorType(), ['Text']

    validateField: (field) ->
      super field

      element = field.element()
      value = element.value.trim()
      isEmpty = false
      if @_emptyValue instanceof RegExp
        isEmpty = @_emptyValue.test value
      else
        isEmpty = value == @_emptyValue

      new formlet.ValidationResult(element, !isEmpty, @_message)

  class RegexFieldValidator extends formlet.FieldValidator
    @fieldValidatorType: ->
      'Regex'

    constructor: (\
        @_regexp
        , @_message = 'Field does not match expected pattern'
        ) ->
      super RegexFieldValidator.fieldValidatorType(), ['Text']

    validateField: (field) ->
      super field

      inputElement = field.inputElement()
      value = inputElement.value.trim()
      isValid = @_regexp.test value
      message = if isValid then null else @_message

      new formlet.ValidationResult(field.element(), isValid, message)

  class Plugin extends formlet.Plugin
    constructor: ->
      formletClasses = [
        OptionsWithOtherFormlet
        ]
      fieldValidatorClasses = [
        RequiredFieldValidator
        , RegexFieldValidator
        ]
      super 'core', {}, formletClasses, fieldValidatorClasses

  formlet.registerPlugin(new Plugin())

do (root = this, factory) ->
  if (typeof define == 'function') and define.amd
    # AMD. Register as an anonymous module.
    define ['formlet'], (formlet) ->
      factory formlet
  else if typeof exports == 'object'
    # Node. Does not work with strict CommonJS, but
    # only CommonJS-like enviroments that support module.exports,
    # like Node.
    formlet = require 'formlet'
    factory formlet
  else
    # Browser globals
    factory root.formlet
