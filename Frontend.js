var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function($, d, w) {
  "use strict";
  var Config, Frontend;
  Frontend = (function() {
    function Frontend() {
      var Abstract;
      this.$ = $;
      this._registry = {};
      this.options = {
        debug: false
      };
      this.Abstract = Abstract = (function() {
        function Abstract() {
          var method, _i, _len, _ref;
          if (!this._exposed) {
            this._exposed = [];
          }
          if (this._exposed.length > 0) {
            _ref = this._exposed;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              method = _ref[_i];
              this.exposeMethod(method);
            }
          }
        }

        Abstract.prototype.setElement = function(el) {
          return this.element = el;
        };

        Abstract.prototype.init = function() {};

        Abstract.prototype.load = function() {};

        Abstract.prototype.ready = function() {
          this.bindings();
          return $(w).load(this.proxy(this.load));
        };

        Abstract.prototype.bindings = function() {};

        Abstract.prototype.isRunnable = function() {
          return true;
        };

        Abstract.prototype.isInitialized = function() {
          return !!this.initialized;
        };

        Abstract.prototype.reinit = function() {
          return this.ready();
        };

        Abstract.prototype.proxy = function(fn) {
          return $.proxy(fn, this);
        };

        Abstract.prototype.exposeMethod = function(method, overwrite) {
          if (overwrite == null) {
            overwrite = false;
          }
          if (w.hasOwnProperty(method) && !overwrite) {
            Frontend.log('method ' + method + ' already exposed');
          }
          return w[method] = this[method];
        };

        return Abstract;

      })();
    }

    Frontend.prototype.register = function(key, obj, selector) {
      if (key in this._registry) {
        this.log("key [" + key + "] already present in _registry: ", this._registry[key]);
        return false;
      }
      return this._registry[key] = {
        object: obj,
        selector: selector
      };
    };

    Frontend.prototype.unregister = function(key) {
      var ret;
      ret = false;
      if (key in this._registry) {
        ret = this._registry[key].object;
      }
      delete this._registry[key];
      return ret;
    };

    Frontend.prototype.registry = function(key) {
      if (!key in this._registry) {
        this.log("key [" + key + "] not found in _registry");
        return false;
      }
      return this._registry[key].object;
    };

    Frontend.prototype.init = function() {
      var self;
      self = this;
      $.each(self._registry, function(k, v) {
        if (typeof v.object === "function" && typeof v.object !== "object") {
          if (typeof v.selector === "string") {
            $(v.selector).each(function(i) {
              self.register(k + '_' + i, new v.object);
              return self.registry(k + '_' + i).setElement(this);
            });
            return self.unregister(k);
          }
        }
      });
      return $.each(self._registry, function(k, v) {
        if ("ready" in v.object && typeof v.object.ready === "function") {
          if (v.object.isRunnable()) {
            v.object.ready();
            return self._registry[k].object.initialized = true;
          }
        }
      });
    };

    Frontend.prototype.trigger = function(evt, obj, parameters) {
      obj = (obj === undefined ? w : obj);
      return $(obj).trigger(evt, parameters);
    };

    Frontend.prototype.log = function() {
      if (this.options && this.options.debug) {
        return w.console && console.log.call(console, arguments_);
      }
    };

    return Frontend;

  })();
  w.Frontend = new Frontend;
  Config = (function(_super) {
    __extends(Config, _super);

    function Config() {
      return Config.__super__.constructor.apply(this, arguments);
    }

    Config.prototype.log = function() {
      return console.log(this);
    };

    return Config;

  })(Abstract);
  w.Frontend.register("config", new Config);
  return $(d).ready(function() {
    return w.Frontend.init();
  });
})(jQuery, document, window);