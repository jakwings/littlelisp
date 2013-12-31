var fs = require('fs');
var repl = require('repl');
var lisp = require('./lisp.js').lisp;

var r = repl.start({
  prompt: 'lisp> ',
  eval: function (cmd, context, filename, callback) {
    var input = cmd.slice(1, -1).trim();
    var result;
    if ('!' === input[0]) {
      var args = input.substr(1).trim().split(' ');
      if (args[0] === 'file') {
        input = fs.readFileSync(args.slice(1).join(' '), {encoding: 'utf8'});
        result = lisp.interpret(input);
      } else {
        result = lisp[args[0]](args.slice(1).join(' '));
      }
    } else {
      result = lisp.interpret(input);
    }
    callback(null, result);
  }
});

r.context.tokenize = lisp.tokenize;
r.context.parse = lisp.parse;

r.on('exit', function () {
  console.log('Bye.');
});
