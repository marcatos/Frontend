Frontend.register_new("slider",
  
  
  class FrontendClass.Slider extends Frontend.Abstract
  
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
      @current = @slides.filter(':visible').eq(0).index()
      
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
      $(@element).removeAttr 'data-config'
      
    setup: ->
      
      # give a class to the slider depending on the configured effect
      $(@element).addClass 'slider-mode-' + @config.effect
      
      # fetch the inner element
      @slider = $('.slider-list',@element)
      
      # validate the effect, to set slide effect jQuery scrollTo is needed (https://github.com/flesler/jquery.scrollTo)
      @config.effect = "fade" if @config.effect is "slide" and "scrollTo" in w
      
      # show the initial page
      @slides.filter(':gt('+(@config.per_page-1)+')').hide() if @is_fade()
      
      # and set the proper width
      @slides.css width: ( ( Math.floor( 10000 / @config.per_page) / 100 ) + '%' ) if @is_slide() && @config.set_dimension
      
    # shortcut method  
    is_fade: ->
      @config.effect is "fade"
    
    # shortcut method  
    is_slide: ->
      @config.effect is "slide"
      
    build_navigation: ->
      
      # create the navigation wrapper
      @navigation = $('<ul>').addClass @config.navigation_class
        
      for s,i in @slides
        # and create an element for each slide
        item = $('<li>').addClass @config.navigation_item_class
        item.addClass @config.navigation_item_class_current if i is @current
        item.appendTo @navigation
        
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
         @start() if @config.autoslide and not @started
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
          @start() if @config.autoslide and not @started
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
      @slides = $(@config.child_selector,@element).filter(':visible')
      @total = @slides.length
        
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
      @current = (@current + 1) % (@total - @config.per_page + 1)
      
      # move
      @to @current
      
    # move to previous
    prev: ->
      
      # but only if we have to
      return if @locked
      
      # update the current index
      @current = (@current + @total - @config.per_page) % (@total - @config.per_page + 1)
      
      # move
      @to @current
      
    # generic move to method, allow non-serial movements
    to: (i)->
      
      # always if we can
      return if @locked
      
      # manage the effect type 
      # fading
      if @is_fade()
        @slides.not(':eq('+i+')').fadeOut()
        @slides.eq(i).fadeIn($.proxy @current_slide_classes,@)
        
      # and sliding
      if @is_slide()
        $(@slider).stop().scrollTo @slides.eq(i), $.extend @config.slide_config, 
          onAfter: $.proxy @current_slide_classes,@
        
      # remember also tu update slider navigation, if present
      if @config.navigation
        @navigation.children().removeClass(@config.navigation_item_class_current).eq(i).addClass @config.navigation_item_class_current
      
    # adjust slides classes, useful to style properly elements
    current_slide_classes: ()->
      @slides.removeClass(@config.child_selector_current);
      @slides.eq(@current).addClass(@config.child_selector_current);
      
    # the rock... no, the slider
    stop: ->
      return if @locked
      
      # and remember that now is stopped
      @started = false
      
      # effective stop
      w.clearInterval @interval

,'.slider')
