(($, d, w) ->
  "use strict"

  class Slider extends Frontend.Abstract
  
    constructor: ->
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
  
    ready: ->
      @init()
      @start() if @config.autoslide
      super

    init: ->
      @read_config()
      @fetch_slide()
      @current = @slides.filter(':visible').eq(0).index()
      if @total <= @config.per_page
        @locked = true
      else
        @locked = false
      @build_navigation() if @config.navigation
      @build_controls() if @config.controls #and not @locked
      @setup()
      $(@element).data 'api',@

    read_config: ->
      $.extend @config, @defaults, $(@element).data 'config'
      @config.slide_config = null if typeof @config.slide_config isnt "object" and @is_slide()
      $(@element).removeAttr 'data-config'
      
    setup: ->
      $(@element).addClass 'slider-mode-'+@config.effect
      @slider = $('.slider-list',@element)
      
      @config.effect = "fade" if @config.effect is "slide" and "scrollTo" in w
      
      @slides.filter(':gt('+(@config.per_page-1)+')').hide() if @is_fade()
      @slides.css width:((Math.floor(10000/@config.per_page)/100)+'%') if @is_slide() && @config.set_dimension
      
    is_fade: ->
      @config.effect is "fade"
      
    is_slide: ->
      @config.effect is "slide"
      
    build_navigation: ->
      @navigation = $('<ul>').addClass @config.navigation_class
      for s,i in @slides
        item = $('<li>').addClass @config.navigation_item_class
        item.addClass @config.navigation_item_class_current if i is @current
        item.appendTo @navigation
      @navigation.appendTo @element
      
    build_controls: ->
      if not @controls.next
        @controls.next = $('<a>').addClass @config.control_next_class
        @controls.next.appendTo @element
        @controls.next.on 'click', $.proxy ->
         @stop()
         @next()
         @start() if @config.autoslide and not @started
        ,@
        
      if not @controls.prev
        @controls.prev = $('<a>').addClass @config.control_prev_class if not @controls.prev
        @controls.prev.appendTo @element
        @controls.prev.on 'click', $.proxy ->
          @stop()
          @prev()
          @start() if @config.autoslide and not @started
        ,@
        
      if @locked
        @controls.next.hide()
        @controls.prev.hide()
      else
        @controls.next.show()
        @controls.prev.show()
        
    fetch_slide: ->
      @slides = $(@config.child_selector,@element).filter(':visible')
      @total = @slides.length
        
    start: ->
      return if @locked or @started
      @started = true
      @interval = w.setInterval $.proxy(@next,@), @config.timeout
      
    next: ->
      return if @locked
      @current = (@current + 1) % (@total - @config.per_page + 1)
      @to @current
      
    prev: ->
      return if @locked
      @current = (@current + @total - @config.per_page) % (@total - @config.per_page + 1)
      @to @current
      
    to: (i)->
      return if @locked
      if @is_fade()
        @slides.not(':eq('+i+')').fadeOut()
        @slides.eq(i).fadeIn($.proxy @current_slide_classes,@)
        
      if @is_slide()
        $(@slider).stop().scrollTo @slides.eq(i), $.extend @config.slide_config, 
          onAfter: $.proxy @current_slide_classes,@
        
      if @config.navigation
        @navigation.children().removeClass(@config.navigation_item_class_current).eq(i).addClass @config.navigation_item_class_current
      
    current_slide_classes: ()->
      @slides.removeClass(@config.child_selector_current);
      @slides.eq(@current).addClass(@config.child_selector_current);
      
    stop: ->
      return if @locked
      @started = false
      w.clearInterval @interval

  Frontend.register("slider", Slider,'.slider');

) Frontend.$, document, window 

