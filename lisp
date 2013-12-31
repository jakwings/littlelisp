#!/usr/bin/env node

var fs = require('fs');
var lisp = require('./lisp.js').lisp;

process.title = 'LISP';
fs.readFile(process.argv[2], {encoding: 'utf8'}, function (err, data) {
  if (err) {
    throw err;
  }
  lisp.interpret(data);
});