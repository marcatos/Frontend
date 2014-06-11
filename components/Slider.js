var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

(function($, d, w) {
  "use strict";
  var Slider;
  Slider = (function(_super) {
    __extends(Slider, _super);

    function Slider() {
      this.defaults = {
        navigation: false,
        autoslide: true,
        timeout: 5000,
        duration: 600,
        child_selector: ".slider-item",
        child_selector_current: "slider-item-current",
        navigation_class: "slider-navigation",
        navigation_item_class: "sprite-sprites-slider-nav",
        navigation_item_class_current: "sprite-sprites-slider-nav-active",
        set_dimension: true,
        controls: false,
        control_next_class: "control next",
        control_prev_class: "control prev",
        per_page: 5,
        effect: "slide",
        slide_config: {
          queue: false,
          duration: 600,
          axis: 'xy'
        }
      };
      this.config = {};
      this.interval = false;
      this.controls = {};
      this.locked = false;
      Slider.__super__.constructor.apply(this, arguments);
    }

    Slider.prototype.ready = function() {
      this.init();
      if (this.config.autoslide) {
        this.start();
      }
      return Slider.__super__.ready.apply(this, arguments);
    };

    Slider.prototype.init = function() {
      this.read_config();
      this.fetch_slide();
      this.current = this.slides.filter(':visible').eq(0).index();
      if (this.total <= this.config.per_page) {
        this.locked = true;
      } else {
        this.locked = false;
      }
      if (this.config.navigation) {
        this.build_navigation();
      }
      if (this.config.controls) {
        this.build_controls();
      }
      this.setup();
      return $(this.element).data('api', this);
    };

    Slider.prototype.read_config = function() {
      $.extend(this.config, this.defaults, $(this.element).data('config'));
      if (typeof this.config.slide_config !== "object" && this.is_slide()) {
        this.config.slide_config = null;
      }
      return $(this.element).removeAttr('data-config');
    };

    Slider.prototype.setup = function() {
      $(this.element).addClass('slider-mode-' + this.config.effect);
      this.slider = $('.slider-list', this.element);
      if (this.config.effect === "slide" && __indexOf.call(w, "scrollTo") >= 0) {
        this.config.effect = "fade";
      }
      if (this.is_fade()) {
        this.slides.filter(':gt(' + (this.config.per_page - 1) + ')').hide();
      }
      if (this.is_slide() && this.config.set_dimension) {
        return this.slides.css({
          width: (Math.floor(10000 / this.config.per_page) / 100) + '%'
        });
      }
    };

    Slider.prototype.is_fade = function() {
      return this.config.effect === "fade";
    };

    Slider.prototype.is_slide = function() {
      return this.config.effect === "slide";
    };

    Slider.prototype.build_navigation = function() {
      var i, item, s, _i, _len, _ref;
      this.navigation = $('<ul>').addClass(this.config.navigation_class);
      _ref = this.slides;
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        s = _ref[i];
        item = $('<li>').addClass(this.config.navigation_item_class);
        if (i === this.current) {
          item.addClass(this.config.navigation_item_class_current);
        }
        item.appendTo(this.navigation);
      }
      return this.navigation.appendTo(this.element);
    };

    Slider.prototype.build_controls = function() {
      if (!this.controls.next) {
        this.controls.next = $('<a>').addClass(this.config.control_next_class);
        this.controls.next.appendTo(this.element);
        this.controls.next.on('click', $.proxy(function() {
          this.stop();
          this.next();
          if (this.config.autoslide && !this.started) {
            return this.start();
          }
        }, this));
      }
      if (!this.controls.prev) {
        if (!this.controls.prev) {
          this.controls.prev = $('<a>').addClass(this.config.control_prev_class);
        }
        this.controls.prev.appendTo(this.element);
        this.controls.prev.on('click', $.proxy(function() {
          this.stop();
          this.prev();
          if (this.config.autoslide && !this.started) {
            return this.start();
          }
        }, this));
      }
      if (this.locked) {
        this.controls.next.hide();
        return this.controls.prev.hide();
      } else {
        this.controls.next.show();
        return this.controls.prev.show();
      }
    };

    Slider.prototype.fetch_slide = function() {
      this.slides = $(this.config.child_selector, this.element).filter(':visible');
      return this.total = this.slides.length;
    };

    Slider.prototype.start = function() {
      if (this.locked || this.started) {
        return;
      }
      this.started = true;
      return this.interval = w.setInterval($.proxy(this.next, this), this.config.timeout);
    };

    Slider.prototype.next = function() {
      if (this.locked) {
        return;
      }
      this.current = (this.current + 1) % (this.total - this.config.per_page + 1);
      return this.to(this.current);
    };

    Slider.prototype.prev = function() {
      if (this.locked) {
        return;
      }
      this.current = (this.current + this.total - this.config.per_page) % (this.total - this.config.per_page + 1);
      return this.to(this.current);
    };

    Slider.prototype.to = function(i) {
      if (this.locked) {
        return;
      }
      if (this.is_fade()) {
        this.slides.not(':eq(' + i + ')').fadeOut();
        this.slides.eq(i).fadeIn($.proxy(this.current_slide_classes, this));
      }
      if (this.is_slide()) {
        $(this.slider).stop().scrollTo(this.slides.eq(i), $.extend(this.config.slide_config, {
          onAfter: $.proxy(this.current_slide_classes, this)
        }));
      }
      if (this.config.navigation) {
        return this.navigation.children().removeClass(this.config.navigation_item_class_current).eq(i).addClass(this.config.navigation_item_class_current);
      }
    };

    Slider.prototype.current_slide_classes = function() {
      this.slides.removeClass(this.config.child_selector_current);
      return this.slides.eq(this.current).addClass(this.config.child_selector_current);
    };

    Slider.prototype.stop = function() {
      if (this.locked) {
        return;
      }
      this.started = false;
      return w.clearInterval(this.interval);
    };

    return Slider;

  })(Frontend.Abstract);
  return Frontend.register("slider", Slider, '.slider');
})(Frontend.$, document, window);
