---
---
{% if site.lightbox.enabled != false %}
document.addEventListener('DOMContentLoaded', function () {
  if (typeof lightbox !== 'undefined') {
    lightbox.option({
      'resizeDuration': {{ site.lightbox.options.resizeDuration | default: 200 }},
      'fadeDuration': {{ site.lightbox.options.fadeDuration | default: 200 }},
      'imageFadeDuration': {{ site.lightbox.options.imageFadeDuration | default: 200 }},
      {% if site.lightbox.options.maxWidth %}'maxWidth': {{ site.lightbox.options.maxWidth }},{% endif %}
      {% if site.lightbox.options.maxHeight %}'maxHeight': {{ site.lightbox.options.maxHeight }},{% endif %}
      'fitImagesInViewport': {{ site.lightbox.options.fitImagesInViewport }},
      'showImageNumberLabel': {{ site.lightbox.options.showImageNumberLabel }},
      'alwaysShowNavOnTouchDevices': {{ site.lightbox.options.alwaysShowNavOnTouchDevices }},
      'wrapAround': {{ site.lightbox.options.wrapAround }},
      'disableScrolling': true
    });
  }
});
{% endif %}