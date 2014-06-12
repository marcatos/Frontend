#
# Frontend - https://github.com/marcatos/Frontend
# Version: 0.1
# Simone Marcato (https://twitter.com/simotenax)
#
# this is framework created to icrease productivity and code readability as main purposes
# it's basically a simple tool where objects are registered and executed depending on their properties
# to maintain these aims it's required to follow some simple coding rules, it would be useless to have the power without using it 
# 

# Shorthands for jQuery, document and window (closure - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Closures)
(($, d, w) ->
  # http://ejohn.org/blog/ecmascript-5-strict-mode-json-and-more/
  "use strict"

  # @class Frontend: main framework class
  class Frontend
    
    # @method constructor: framework constructor with main properties setup
    constructor: () ->
      # embed jQuery into Frontend to prevent accidental multiple jQuery inclusions and overwriting
      @$ = $
      # magnificent registry, simply a stack in which store objects
      @_registry = {}
      # global options, now has only debug flag, it can be extended
      @options =
        debug: false
      # abstract class link to Frontend's property to reuse it without exposing it directly into the document
        
      # @class abstract: that must be extended to work properly with Frontend framework
      @Abstract =
        class Abstract
          
          # @method constructor: main object constructor
          constructor: ->
            # expose what need to be exposed
            @_exposed = [] if not @_exposed
            if @_exposed.length > 0
              for method in @_exposed
                @exposeMethod method
          
          # @method setElement: automatically used to bind onLoad function on window object, note: if you don't call @ready() of Abstract class this is not done automatically setElement: used directly from Frontend framework to register sets of elements corresponding to elements added dynamically 
          # @param el: DOM Object
          setElement: (el)->
            @element = el
            
          # @method util: not yet used  
          init: ->
      
          # @method load: automatically used to bind onLoad function on window object, note: if you don't call @ready() of Abstract class this is not done automatically (this is a common mistake) 
          load: ->
      
          # @method ready: calls bindings and binds load function on window load, if the object is runnable it's called on document ready
          ready: ->
            @bindings()
            $(w).load @proxy @load
      
          # @method bindings: as for other methods this is used only to organize code, in particular this function would wrap all event bindings, called on ready method
          bindings: ->
      
          # @method isRunnable: called from Frontend framework to know if the registered object is also runnable; this is useful to exploit browser caching system, you have only to include all your JS code everywhere leaving to Frontend framework the run policy
          # @return boolean: default true, that means always runnable
          isRunnable: ->
            true
            
          # @method isInitialize: not yet used, the ideal aim is to manage automatically object re-initialization
          isInitialized: ->
            !!@initialized
      
          # @method reinit: calls @ready, not useful at the moment, the future aim is the same for @isIinitialized
          reinit: ->
            @ready()
            
          # @method proxy: util to use jQuery callback keeping the original object context, use with care, it's not always needed to have the actual object as context, you can call it with a workaround (see documentation - https://github.com/marcatos/Frontend/wiki/Documentation#context)
          proxy: (fn)->
            return $.proxy fn,@
            
          # @method exposeMethod: allow to expose directly methods as global functions
          exposeMethod: (method, overwrite = false)->
            if w.hasOwnProperty(method) and not overwrite
              Frontend.log 'method '+method+' already exposed'
            w[method] = @[method]


    # register, unregister, registry - thankyou Magento for your inspiring code
    
    # @method register: setter - stores object associated with a unique key, checks if key already exists; if selector parameter is specified the obj is expected as function type (class) instead of Object (class instance), in this case key is used as key prefix appending incremental counter
    # @param (string) key: unique key to store and retrive the object
    # @param (function|Object) obj: the object to store or the class to use for instantiate objects dynamically by selector
    # @param (strin) selector: jQuery style selector
    register: (key, obj, selector) ->
      if key of @_registry
        @log "key [" + key + "] already present in _registry: ", @_registry[key]
        return false
      @_registry[key] = {object:obj,selector:selector}

    # @method register: removes object registered by key, used to update registry key (needed in very few cases)   
    # @param (string) key: unique key to retrive and delete the object 
    unregister: (key) ->
      ret = false
      ret = @_registry[key].object  if key of @_registry
      delete @_registry[key]
      ret
      
    # @method registry: getter - retrive and return object by key, 
    registry: (key) ->
      if not key of @_registry
        @log "key [" + key + "] not found in _registry"
        return false
      @_registry[key].object
      
    # @method init: framework bootstrap method, it checks and loads registered elements
    init: ->
      
      # save the context
      self = @
      
      # dynamic object instantiation, if selector is specified during register
      $.each self._registry, (k, v) ->
        
        if typeof (v.object) is "function" and typeof (v.object) isnt "object"
          if typeof(v.selector) is "string"
            
            # loop over selector
            $(v.selector).each (i)->
              
              # register new object
              self.register k+'_'+i, new v.object
              self.registry(k+'_'+i).setElement this
              
            # unregister the original item (do I need this?)
            self.unregister k
              
      # loop over registered objects 
      $.each self._registry, (k, v) ->
            
        # check if object is runnable
        if "ready" of v.object and typeof (v.object.ready) is "function"
          if v.object.isRunnable()
            
            # run it
            v.object.ready()
            self._registry[k].object.initialized = true

    # @method trigger: jQuery.trigger wrapper, useful again for not exposing directly jQuery object into document
    trigger: (evt, obj, parameters) ->
      obj = (if obj is `undefined` then w else obj)
      $(obj).trigger evt, parameters
    
    # @method log: console.log wrapper, prevents exceptions thrown by forgotten debug code lines
    log: ->
      w.console and console.log.call(console, arguments_)  if @options and @options.debug
  
  # expose the framework  
  w.Frontend = new Frontend;

  # contextually used to store settings as object property server side 
  class Config extends w.Frontend.Abstract
    log: ->
      console.log @
  
  w.Frontend.register("config", new Config);

  # run the Frontend
  $(d).ready ->
    w.Frontend.init()

) jQuery, document, window