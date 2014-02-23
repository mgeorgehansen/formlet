# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

define ['jquery', 'formlet'], ($, Formlet) ->
  $messages = $ '#messages'
  $formElement = $ '#form1'

  clearErrors = ->
    ($formElement.find '.error').removeClass 'error'
    clearMessages()

  clearMessages = ->
    ($messages.find '.messages--list').remove()

  addMessage = (message) ->
    $messagesList = $messages.find '.messages--list'
    if ($messagesList.length == 0)
      $messages.append '<ul class="messages--list">'
      $messagesList = $messages.find '.messages--list'

    $messageListElement = $ '<li class="messages--list-element">'
    $message = $ "<div class=\"message\">#{message}</div>"
    $messageListElement.append $message
    $messagesList.append $messageListElement

  $optionFieldElement = $formElement.find '[data-formlet-field=option]'
  $optionElements = $optionFieldElement.find 'input[type=radio]'
  optionField = new Formlet.OptionField(
    $optionFieldElement.get(0)
    , $optionElements.toArray()
    , []
    )

  $otherFieldElement = $formElement.find '[data-formlet-field=text]'
  $otherInputElement = $otherFieldElement.find 'input[type=text]'
  otherField = new Formlet.TextField(
    $otherFieldElement.get(0)
    , $otherInputElement.get(0)
    , [
        new Formlet.RegexFieldValidator(
          /^[1-9]?[0-9]+$/
          , 'You must enter a number'
          )
      ]
    )

  $formletElement = $formElement.find '[data-formlet]'
  formlet = new Formlet.OptionsWithOtherFormlet(
    $formletElement.get(0)
    , optionField
    , otherField
    )

  form = new Formlet.Form($formElement.get(0), [ formlet ])

  $formElement.on 'submit', (event) ->
    event.preventDefault()
    clearErrors()
    errors = (r for r in form.validate() when !r.isValid())
    if errors.length > 0
      for error in errors
        ($ error.target()).addClass 'error'
        addMessage error.message()

  # Clear options when other is focused and vice-versa.
  $otherInputElement.on 'focus', ->
    $optionElements.attr 'checked', false
  $optionElements.on 'focus', ->
    $otherInputElement.val ''
