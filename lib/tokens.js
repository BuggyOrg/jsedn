// Generated by CoffeeScript 1.10.0
(function() {
  var Char, StringObj, Tag, bigInt, char, handleToken, kw, ref, sym, tokenHandlers;

  ref = require("./atoms"), Char = ref.Char, StringObj = ref.StringObj, char = ref.char, kw = ref.kw, sym = ref.sym, bigInt = ref.bigInt;

  Tag = require("./tags").Tag;

  handleToken = function(token) {
    var handler, name;
    if (token instanceof StringObj) {
      return token.toString();
    }
    for (name in tokenHandlers) {
      handler = tokenHandlers[name];
      if (handler.pattern.test(token)) {
        return handler.action(token);
      }
    }
    return sym(token);
  };

  tokenHandlers = {
    nil: {
      pattern: /^nil$/,
      action: function(token) {
        return null;
      }
    },
    boolean: {
      pattern: /^true$|^false$/,
      action: function(token) {
        return token === "true";
      }
    },
    keyword: {
      pattern: /^[\:].*$/,
      action: function(token) {
        return kw(token);
      }
    },
    char: {
      pattern: /^\\.*$/,
      action: function(token) {
        return char(token.slice(1));
      }
    },
    integer: {
      pattern: /^[\-\+]?[0-9]+N?$/,
      action: function(token) {
        if (/\d{15,}/.test(token)) {
          return bigInt(token);
        }
        return parseInt(token === "-0" ? "0" : token);
      }
    },
    float: {
      pattern: /^[\-\+]?[0-9]+(\.[0-9]*)?([eE][-+]?[0-9]+)?M?$/,
      action: function(token) {
        return parseFloat(token);
      }
    },
    tagged: {
      pattern: /^#.*$/,
      action: function(token) {
        return new Tag(token.slice(1));
      }
    }
  };

  module.exports = {
    handleToken: handleToken,
    tokenHandlers: tokenHandlers
  };

}).call(this);
