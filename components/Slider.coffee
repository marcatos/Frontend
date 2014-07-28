(($, d, w) ->
  "use strict"
  Frontend.register "slider", 
    # extends Abstract to work properly with framework
    class Slider extends Frontend.Abstract

      constructor: ->

        # default settings
        @defaults = {
          navigation: false
          autoslide: true
          timeout: 5000
          duration: 600
          child_selector: ".slider-item"
          child_selector_current: "slider-item-current"
          navigation_class: "slider-navigation"
          navigation_item_class: "sprite-sprites-slider-nav"
          navigation_item_class_current: "sprite-sprites-slider-nav-active"
          set_dimension: true
          controls: false
          control_next_class: "control next"
          control_prev_class: "control prev"
          per_page: 5
          effect: "slide"
          circular: true
          bind_navigation: true
          start_after_click: true
          slide_config: {
            queue: false,
            duration: 600,
            axis: 'xy'
          }
        }
        @config = {}
        @interval = false
        @controls = {}
        @locked = false

        # call parent constructor
        super

      ready: ->

        # on document ready init the object
        @init()

        # and then start the slider if configured
        @start() if @config.autoslide

        super

      init: ->

        # read config and merge with defaults
        @read_config()

        # fetch slides element
        @fetch_slide()

        # what's the current slide
        @current = @visibleSlides.filter(':visible').eq(0).index()

        # do we have enough slides
        if @total <= @config.per_page
          # if not lock the slider
          @locked = true
        else
          @locked = false

        # build slider navigation if needed  
        @build_navigation() if @config.navigation

        # build next and prev controls if needed
        @build_controls() if @config.controls

        #set it up
        @setup()

        # give api access from DOM element
        $(@element).data 'api',@

      read_config: ->

        # extend defaults with connfiguration from data-config
        $.extend @config, @defaults, $(@element).data 'config'

        # specific check for slide_config, it must be an object, but only if slide effect is set
        @config.slide_config = null if typeof @config.slide_config isnt "object" and @is_slide()

        # hide the initial config (useless but cleaner code while inspecting)
        # $(@element).removeAttr 'data-config'

      setup: ->

        # give a class to the slider depending on the configured effect
        $(@element).addClass 'slider-mode-' + @config.effect

        # fetch the inner element
        @slider = $('.slider-list',@element)

        # validate the effect, to set slide effect jQuery scrollTo is needed (https://github.com/flesler/jquery.scrollTo)
        @config.effect = "fade" if @config.effect is "slide" and "scrollTo" in w

        # show the initial page
        @visibleSlides.filter(':gt('+(@config.per_page-1)+')').hide() if @is_fade()

        # and set the proper width
        @slidesWidth = Math.floor( 10000 / @config.per_page) / 100
        @visibleSlides.css width: ( @slidesWidth + '%' ) if @is_slide() && @config.set_dimension

      # shortcut method  
      is_fade: ->
        @config.effect is "fade"

      # shortcut method  
      is_slide: ->
        @config.effect is "slide"

      build_navigation: ->
        self = @
        
        # create the navigation wrapper
        @navigation = $('<ul>').addClass @config.navigation_class
        
        for s,i in @slides
          # and create an element for each slide
          item = $('<li>').addClass(@config.navigation_item_class).text(i+1)
          item.addClass @config.navigation_item_class_current if i is @current
          ((i, self)->
            if self.config.bind_navigation
              item.on 'click', ->
                self.stop()
                self.to(i)
                self.start() if self.config.autoslide and not self.started and self.config.start_after_click
          ) i, @
          item.appendTo @navigation
        
        @navigation.addClass 'clickable' if @config.bind_navigation
        # show it
        @navigation.appendTo @element

      build_controls: ->

        # check if next control is already attached
        if not @controls.next

          # in case, create it
          @controls.next = $('<a>').addClass @config.control_next_class
          @controls.next.appendTo @element

          # and then binf the real control
          @controls.next.on 'click', $.proxy ->
            @stop()
            @next()
            # start only if needed and isn't started yet
            @start() if @config.autoslide and not @started and @config.start_after_click
          ,@

        # same for prev control
        # check if next control is already attached
        if not @controls.prev

          # in case, create it
          @controls.prev = $('<a>').addClass @config.control_prev_class if not @controls.prev
          @controls.prev.appendTo @element
          @controls.prev.on 'click', $.proxy ->
            @stop()
            @prev()
            # start only if needed and isn't started yet
            @start() if @config.autoslide and not @started and @config.start_after_click
          ,@

        # once controls are built, check if we need to see them, useful when slides change after the firt document load
        if @locked
          @controls.next.hide()
          @controls.prev.hide()
        else
          @controls.next.show()
          @controls.prev.show()

      # caching is golden, fetch slide to not look for them every time
      fetch_slide: ->

        # we care about only visible elements
        @slides = $(@config.child_selector,@element)
        @visibleSlides = @slides.filter(':visible')
        @total = @visibleSlides.length

      # commont slider start method
      start: ->
      
        # if is locked or already started no need to restart
        return if @locked or @started
        
        # yes, we started
        @started = true

        # once started continue the loop
        @interval = w.setInterval $.proxy(@next,@), @config.timeout

      # move to next
      next: ->

        # again prevent unexpected interactions
        return if @locked

        # update the current index
        oldCurrent = @current
        @current = (@current + 1) % (@total - @config.per_page + 1)
        # @direction = (if oldCurrent < @current then 1 else -1)
        @direction = 1

        # move
        @to @current

      # move to previous
      prev: ->

        # but only if we have to
        return if @locked

        # update the current index
        @current = (@current + @total - @config.per_page) % (@total - @config.per_page + 1)
        @direction = -1

        # move
        @to @current

      # generic move to method, allow non-serial movements
      to: (i)->
        self = @

        # always if we can
        return if @locked

        # manage the effect type 
        # fading
        if @is_fade()
          @visibleSlides.not(':eq('+i+')').fadeOut()
          @visibleSlides.eq(i).fadeIn($.proxy @current_slide_classes,@)

        # and sliding
        if @is_slide()
        
          if @config.circular is true

            # keep track of the total element to wait before run onAfterSlider
            @config.slide_config.complete = ->
              self.slidesAnimationCounter++
              self.onAfterSlide() if self.slidesAnimationCounter is self.slides.length

            @slidesAnimationCounter = 0

            # if is prev adjust then animate
            if @direction is -1
              @slides.eq(@slides.length-1).insertBefore(@slides.eq(0))
              @slides.css
                left: '-'+self.slidesWidth+'%'
              @slides.each (i)->
                $(@).animate
                  left: '0'
                , self.config.slide_config

            # if is next animate then adjust
            if @direction is 1
              @slides.each (i)->
                $(@).animate
                  left: '-'+self.slidesWidth+'%'
                , self.config.slide_config
          else
            $(@slider).stop().scrollTo @visibleSlides.eq(i), $.extend @config.slide_config, 
              onAfter: $.proxy @current_slide_classes,@

        # remember also tu update slider navigation, if present
        if @config.navigation
          @navigation.children().removeClass(@config.navigation_item_class_current).eq(i).addClass @config.navigation_item_class_current

      # adjust slides classes, useful to style properly elements
      current_slide_classes: ()->
        @visibleSlides.removeClass(@config.child_selector_current);
        @visibleSlides.eq(@current).addClass(@config.child_selector_current);

      # the rock... no, the slider
      stop: ->
        return if @locked

        # and remember that now is stopped
        @started = false
        
        # effective stop
        w.clearInterval @interval
        
      onAfterSlide: ->
        # adjust after if direction is next
        if @direction is 1
          @slides.eq(0).insertAfter(@slides.eq(@slides.length-1))
          
        # prepare for the next cycle
        @fetch_slide()
        @slides.css
          left: 0
        

  ,'.slider'

) Frontend.$, document, window 

