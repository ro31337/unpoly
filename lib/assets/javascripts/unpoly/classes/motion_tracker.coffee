u = up.util

class up.MotionTracker

  constructor: (name) ->
    @className = "up-#{name}"
    @dataKey = "up-#{name}-finished"
    @selector = ".#{@className}"
    @finishEvent = "up:#{name}:finish"

  ###*
  Finishes all animations in the given element's ancestors and descendants,
  then calls the animator.

  @method claim
  @param {jQuery} $element
  @param {Function(jQuery): Promise} animator
  @return {Promise} A promise that is fulfilled when the new animation ends.
  ###
  claim: ($element, animator) =>
    @finish($element).then =>
      @start($element, animator)

  ###*
  Calls the given animator to animate the given element.

  The animation returned by the animator is tracked so it can be
  [`finished`](/up.MotionTracker.finish) later.

  No animations are finished before starting the new animation.
  Use [`claim()`](/up.MotionTracker.claim) for that.

  @method claim
  @param {jQuery} $element
  @param {Function(jQuery): Promise} animator
  @return {Promise} A promise that is fulfilled when the new animation ends.
  ###
  start: ($element, animator) ->
    promise = animator($element)
    @markElement($element, promise)
    promise.then => @unmarkElement($element)
    promise

  ###*
  @method finish
  @param {jQuery} [elements]
    If no element is given, finishes all animations in the documnet.
    If an element is given, only finishes animations in its subtree and ancestors.
  @return {Promise} A promise that is fulfilled when animations have finished.
  ###
  finish: (elements) =>
    $elements = @expandFinishRequest(elements)
    allFinished = u.map($elements, @finishOneElement)
    Promise.all(allFinished)

  expandFinishRequest: (elements) ->
    if elements
      u.selectInDynasty($(elements), @selector)
    else
      $(@selector)

  finishOneElement: (element) =>
    $element = $(element)
    finished = $element.data(@name)
    @unmarkElement($element)

    # Animating code is expected to listen to this event and fast-forward
    # the animation if triggered. All built-ins like `up.animate`, `up.morph`,
    # or `up.scroll` behave that way.
    #
    # If animating code ignores the event, we cannot force the animation to
    # finish from here. We will wait for the animation to end naturally before
    # starting the next animation.
    $element.trigger(@finishEvent)

    # There are some cases related to element ghosting where an element
    # has the class, but not the data value. In that case simply return
    # a resolved promise.
    finished || Promise.resolve()

  markElement: ($element, promise) =>
    $element.addClass(@className)
    $element.attr('wtf-attr', 'wtf-value')
    console.info("!!! Adding #{@className} to %o", $element.get())
    console.info("!!! className is now %o", $element.get(0).className)
    $element.data(@dataKey, promise)

  unmarkElement: ($element) =>
    $element.removeClass(@className)
    $element.removeData(@dataKey)