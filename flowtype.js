'use strict';

// FlowType: https://github.com/simplefocus/FlowType.JS/blob/master/flowtype.js
(function () {
  if ( window.hasFlowType ) {
    return;
  }
  var change = function () {
    var maxWidth = 960, minWidth = 450;
    var maxSize = 16, minSize = 12;
    var fontRatio = 35, lineRatio = 1.45;
    var elem = document.body;
    var elemWidth = elem.getClientRects()[0].width;
    var width = elemWidth > maxWidth ? maxWidth
                : elemWidth < minWidth ? minWidth
                : elemWidth;
    var fontBase = width / fontRatio;
    var fontSize = fontBase > maxSize ? maxSize
                   : fontBase < minSize ? minSize
                   : fontBase;
    elem.style.fontSize = fontSize + 'px';
    //elem.style.lineHeight = fontSize*lineRatio + 'px';
  };
  window.addEventListener('resize', change, true);
  change();
  window.hasFlowType = true;
})();
