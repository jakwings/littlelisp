/******************************************************************************\
 * Date: 2013-12-30 20:31:21 +08:00
 * Author: Jak Wings
 * Copyleft: All rights reversed.
 * Website:
 * Thanks to: https://github.com/maryrosecook/littlelisp
 * Description:
 *   A custom simple call-by-value LISP interpreter implemented in Javascript.
 *   It has keywords like "define"(not macro), "let" and "if", and basic types
 *   "function", "double", "string", "boolean"(implicit). It also supports
 *   currying without particular specification of function definitions. No
 *   supporting for syntax checking nor error throwing. ;-)
\******************************************************************************/
;(function (exports) {
'use strict';


/******************************************************************************\
 * Lexer
\******************************************************************************/

/**
 * tokenizes one LISP expression and returns uncategorized tokens
 * @param {string} input LISP code
 * @return {Array.<string>}
 */
var tokenize = function (input) {
  return input.
      replace(/(\(|\))(?=(?:[^"]*"[^"]*")*[^"]*$)/g, ' $1 ').
      trim().
      split(/\s+(?=(?:[^"]*"[^"]*")*[^"]*$)/);
};


/******************************************************************************\
 * Parser
\******************************************************************************/

/**
 * parses tokens of one LISP expression and returns the AST
 * @param {Array.<string>} tokens tokens of one LISP expression
 * @param {Array.<(Array|Token)>} opt_list AST
 * @return {(Array|Token)}
 */
var parse = function (tokens, opt_list) {
  if (!opt_list) {
    opt_list = [];
  }
  var token = tokens.shift();
  if (!token) {
    return opt_list.pop();
  } else if (token === '(') {
    opt_list.push(parse(tokens));
    return parse(tokens, opt_list);
  } else if (token === ')') {
    return opt_list;
  } else {
    opt_list.push(categorize(token));
    return parse(tokens, opt_list);
  }
};

/**
 * Token class, for categorized tokens
 * @constructor
 * @param {string} type literal | identifier
 * @param {string} value
 */
var Token = function (type, value) {
  this.type = type;
  this.value = value;
};

/**
 * categorizes one token and return a the categorized token
 * @param {string} token
 * @return {Token}
 */
var categorize = function (token) {
  var number = parseFloat(token);
  if (!isNaN(number)) {
    return new Token('literal', number);
  } else if (token[0] === '"' && token.slice(-1) === '"') {
    return new Token('literal', token.slice(1, -1));
  } else {
    return new Token('identifier', token);
  }
};


/******************************************************************************\
 * Interpreter
\******************************************************************************/

/**
 * Context class, for runtime environments
 * @constructor
 * @param {Object.<string, *>} scope runtime environment
 * @param {Context=} opt_parent parent context
 * @default undefined
 */
var Context = function (scope, opt_parent) {
  this.scope = scope;
  this.parent = opt_parent;
  this.get = function (name) {
    if (name in this.scope) {
      return this.scope[name];
    } else if (this.parent) {
      return this.parent.get(name);
    }
  };
  this.set = function (name, value) {
    this.scope[name] = value;
  };
};

/**
 * interprets one AST and return the result
 * @param {(Array|Token)} node AST
 * @param {Context=} opt_context runtime environment
 * @default environment
 * @return {*}
 */
var interpret = function (node, opt_context) {
  if (!opt_context) {
    opt_context = environment;
  }
  if (node instanceof Array) {
    return interpretList(node, opt_context);
  } else if (node.type === 'identifier') {
    return opt_context.get(node.value);
  } else {
    return node.value;
  }
};

/**
 * interprets AST and return the result
 * @param {Array} nodes AST
 * @param {Context} context runtime environment
 * @return {*}
 */
var interpretList = function (nodes, context) {
  if (nodes[0] && nodes[0].value in keywords) {
    return keywords[nodes[0].value](nodes, context);
  } else {
    var atoms = nodes.map(function (node) {
      return interpret(node, context);
    });
    if (atoms[0] instanceof Function) {
      return funcall(atoms);
    } else {
      return atoms;
    }
  }
};

/**
 * applies function to the rest of the list and return the result
 * supports currying, like: ((+ 1) 4) -> 5, ((lambda (x) (+ x)) 1 4) -> 5
 * @param {Array} atoms
 * @return {*}
 */
var funcall = function (atoms) {
  var func = atoms[0];
  var args = atoms.slice(1);
  var funcLength = func.length_ || func.length;
  var isCurrying = true;
  while (func instanceof Function && isCurrying) {
    isCurrying = args.length > funcLength;
    var tmpArgs = args.splice(0, funcLength);
    funcLength -= tmpArgs.length;
    if (tmpArgs.length) {
      tmpArgs.unshift(undefined);
      func = func.bind.apply(func, tmpArgs);
      func.length_ = funcLength;
    }
    if (!tmpArgs.length || funcLength <= 0) {
      func = func();
      if (func instanceof Function) {
        funcLength = func.length_ || func.length;
      } else {
        isCurrying = false;
      }
    }
    if (!args.length) { break; }
  }
  return func;
};

/**
 * keywords of LISP
 * @type {Object.<string, function(Array, Context)>}
 */
var keywords = {
  /// e.g. (((lambda (x) (lambda (y) (+ x y))) 8) 4)
  'lambda': function (nodes, context) {
    var func = function () {
      var lambdaArguments = arguments;
      var lambdaScope = nodes[1].reduce(function (acc, node, i) {
        acc[node.value] = lambdaArguments[i];
        return acc;
      }, {});
      return interpret(nodes[2], new Context(lambdaScope, context));
    };
    func.length_ = nodes[1].length;  // allow currying (buggy)
    return func;
  },
  /// e.g (define I (lambda (x) x)) or (define (f x y) (+ x y))
  'define': function (nodes, context) {
    if (nodes[1] instanceof Array) {
      environment.set(nodes[1][0].value, this.lambda(
          ['lambda', nodes[1].slice(1), nodes[2]], environment));
    } else {
      environment.set(nodes[1].value, interpret(nodes[2], environment));
    }
  },
  /// e.g. (let ((x 3) (y 4)) (+ x y))
  'let': function (nodes, context) {
    var letScope = nodes[1].reduce(function (acc, nodes) {
      acc[nodes[0].value] = interpret(nodes[1], context);
      return acc;
    }, {});
    return interpret(nodes[2], new Context(letScope, context));
  },
  /// e.g (if (> 0 1) "Y" "N")
  'if': function (nodes, context) {
    return interpret(nodes[1], context) ?
        interpret(nodes[2], context) : interpret(nodes[3], context);
  }
};

/**
 * default runtime environment
 * @type {Context}
 */
var environment_ = new Context({
  '==': function (a, b) { return a === b; },
  '!=': function (a, b) { return a !== b; },
  '<': function (a, b) { return a < b; },
  '<=': function (a, b) { return a <= b; },
  '>': function (a, b) { return a > b; },
  '>=': function (a, b) { return a >= b; },
  '+': function (a, b) { return a + b; },
  '-': function (a, b) { return a - b; },
  '*': function (a, b) { return a * b; },
  '/': function (a, b) { return a / b; },
  '%': function (a, b) { return a % b; },
  '^': function (a, b) { return a ^ b; },
  'print': function (x) {
    console.log(x);
    return x;
  }
});

/**
 * global runtime environment
 * @type {Context}
 */
var environment = new Context({}, environment_);


/******************************************************************************\
 * Multi-expression Interpreter
\******************************************************************************/

var run = function (input) {
  var evaluate = function (expr) {
    return interpret(parse(tokenize(expr)));
  };
  var lastResult;
  var parenDelta = 0;
  var stringOn = false;
  var inlineCommentOn = false;
  var i = 0, s = '';;
  for (var c; typeof (c = input[i]) !== 'undefined'; i++) {
    s += c;
    if (inlineCommentOn) {
      if (c !== '\r' && c !== '\n') {
        continue;
      } else {
        inlineCommentOn = false;
      }
    }
    switch (c) {
      case '"':
        stringOn = !stringOn;
        break;
      case '(':
        if (!stringOn) {
          parenDelta++;
        }
        if (!parenDelta && s.trim()) {
          lastResult = evaluate(s);
          s = '';
        }
        break;
      case ')':
        if (!stringOn) {
          parenDelta--;
        }
        if (!parenDelta) {
          lastResult = evaluate(s);
          s = '';
        }
        break;
      case ';':
        if (!stringOn) {
          inlineCommentOn = true;
        }
        break;
      default: break;
    }
  }
  return s.trim() ? evaluate(s) : lastResult;
};


/******************************************************************************\
 * exports to web browsers or node applications
\******************************************************************************/
exports.lisp = {
  tokenize: tokenize,
  parse: function (input) { return parse(tokenize(input)); },
  interpret: run,
  reset: function () { environment = new Context({}, environment_); }
};
})(typeof exports === 'undefined' ? this : exports);