'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var fs = require('fs');

function _arrayWithHoles(arr) {
  if (Array.isArray(arr)) return arr;
}

var arrayWithHoles = _arrayWithHoles;

function _iterableToArrayLimit(arr, i) {
  if (!(Symbol.iterator in Object(arr) || Object.prototype.toString.call(arr) === "[object Arguments]")) {
    return;
  }

  var _arr = [];
  var _n = true;
  var _d = false;
  var _e = undefined;

  try {
    for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
      _arr.push(_s.value);

      if (i && _arr.length === i) break;
    }
  } catch (err) {
    _d = true;
    _e = err;
  } finally {
    try {
      if (!_n && _i["return"] != null) _i["return"]();
    } finally {
      if (_d) throw _e;
    }
  }

  return _arr;
}

var iterableToArrayLimit = _iterableToArrayLimit;

function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance");
}

var nonIterableRest = _nonIterableRest;

function _slicedToArray(arr, i) {
  return arrayWithHoles(arr) || iterableToArrayLimit(arr, i) || nonIterableRest();
}

var slicedToArray = _slicedToArray;

function _classCallCheck(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

var classCallCheck = _classCallCheck;

function _defineProperties(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, descriptor.key, descriptor);
  }
}

function _createClass(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties(Constructor, staticProps);
  return Constructor;
}

var createClass = _createClass;

function _defineProperty(obj, key, value) {
  if (key in obj) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
  } else {
    obj[key] = value;
  }

  return obj;
}

var defineProperty = _defineProperty;

var commonjsGlobal = typeof globalThis !== 'undefined' ? globalThis : typeof window !== 'undefined' ? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};

function createCommonjsModule(fn, module) {
	return module = { exports: {} }, fn(module, module.exports), module.exports;
}

var tsv = createCommonjsModule(function (module) {
(function(){

    var br = "\n";

    function extend (o) {
        Array.prototype.slice.call(arguments, 1).forEach(function(source){
            if (!source) return
            for (var keys = Object.keys(source), i = 0; i < keys.length; i++) {
                var key = keys[i];
                o[key] = source[key];
            }
        });
        return o
    }

    function unquote (str) {
        var match;
        return (match = str.match(/(['"]?)(.*)\1/)) && match[2] || str
    }

    function comments (line) {
        return !/#@/.test(line[0])
    }

    function getValues (line, sep) {
        return line.split(sep).map(function(value){
            var value = unquote(value), num = +value;
            return num === parseInt(value, 10) ? num : value
        })
    }

    function Parser (sep, options) {
        var opt = extend({
            header: true
        }, options);

        this.sep = sep;
        this.header = opt.header;
    }

    Parser.prototype.stringify = function (data) {
        var sep    = this.sep
          , head   = !!this.header
          , keys   = (typeof data[0] === 'object') && Object.keys(data[0])
          , header = keys && keys.join(sep)
          , output = head ? (header + br) : '';

        if (!data || !keys) return ''
            
        return output + data.map(function(obj){
            var values = keys.reduce(function(p, key){
                p.push(obj[key]);
                return p
            }, []);
            return values.join(sep)
        }).join(br)
    };

    Parser.prototype.parse = function (tsv) {
        var sep   = this.sep
          , lines = tsv.split(/[\n\r]/).filter(comments)
          , head  = !!this.header
          , keys  = head ? getValues(lines.shift(), sep) : {};

        if (lines.length < 1) return []

        return lines.reduce(function(output, line){
            var item = head ? {} : [];
            output.push(getValues(line, sep).reduce(function(item, val, i){
                item[keys[i] || i] = val;
                return item
            }, item));
            return output
        }, [])
    };

    // Export TSV parser as main, but also expose `.TSV`, `.CSV` and `.Parser`.
    var TSV = new Parser("\t");

    extend(TSV, {
        TSV    : TSV
      , CSV    : new Parser(",")
      , Parser : Parser
    });

    if ( module.exports){
        module.exports = TSV;
    } else {
        this.TSV = TSV;
    }

}).call(commonjsGlobal);
});

var _temp, _data;
var Roles = (_temp =
/*#__PURE__*/
function () {
  function Roles(file) {
    classCallCheck(this, Roles);

    _data.set(this, {
      writable: true,
      value: void 0
    });

    var contents = fs.readFileSync(file, 'utf8');
    var lines = contents.split("\n");
    var filteredLines = lines.filter(function (line) {
      return !line.match(/^\s*$/);
    });
    this.data = tsv.parse(filteredLines.join("\n"));
  }

  createClass(Roles, [{
    key: "length",
    get: function get() {
      return this.data.length;
    }
  }]);

  return Roles;
}(), _data = new WeakMap(), _temp);

var _temp$1, _docDir, _roles, _rolesFile, _terms;
var Policies = (_temp$1 =
/*#__PURE__*/
function () {
  function Policies() {
    classCallCheck(this, Policies);

    _docDir.set(this, {
      writable: true,
      value: void 0
    });

    _roles.set(this, {
      writable: true,
      value: void 0
    });

    _rolesFile.set(this, {
      writable: true,
      value: void 0
    });

    _terms.set(this, {
      writable: true,
      value: void 0
    });

    defineProperty(this, "sourceFiles", void 0);

    this.sourceFiles = [];
    this.rolesFile = 'roles.tsv';
    this.terms = [];
  }

  createClass(Policies, [{
    key: "addSourceFile",
    value: function addSourceFile(fileName) {
      this.sourceFiles.push(fileName);
    }
  }, {
    key: "setRolesFile",
    value: function setRolesFile(name) {
      this.rolesFile = name;
    }
  }, {
    key: "getRoles",
    value: function getRoles() {
      if (this.roles !== undefined) return this.roles;
      var rolesFile = this.findFile(this.rolesFile);
      this.roles = new Roles(rolesFile);
      return this.roles;
    }
  }, {
    key: "findFile",
    value: function findFile(baseName) {
      var re = new RegExp("/".concat(baseName, "$"));
      var results = this.sourceFiles.filter(function (f) {
        return f.match(re);
      });
      if (results.length > 1) throw new Error("Found multiple files matching '".concat(baseName, "'"));else if (results.length === 0) return null;else return results[0];
    }
  }, {
    key: "addTerm",
    value: function addTerm(term, definition) {
      this.terms.push([term, definition]);
    }
  }, {
    key: "setDocumentDir",
    value: function setDocumentDir(dir) {
      this.docDir = dir;
    }
  }, {
    key: "generateDocuments",
    value: function generateDocuments() {
      var _this = this;

      if (this.docDir === undefined) throw new Error('No document directory defined.');
      if (!fs.existsSync(this.docDir)) throw new Error("Target document dir '".concat(this.docDir, "' does not exist."));
      var roles = this.getRoles();
      roles.data.forEach(function (i) {
        _this.addTerm(i['Role Name'], i['Job Description']);
      });
      var glossaryContent = "# Glossary\n\n<dl>";
      this.terms.sort(function (a, b) {
        return a[0].localeCompare(b[0]);
      });
      this.terms.forEach(function (_ref) {
        var _ref2 = slicedToArray(_ref, 2),
            term = _ref2[0],
            def = _ref2[1];

        return glossaryContent += "  <dt>".concat(term, "</dt>\n  <dd>").concat(def, "</dd>\n\n");
      });
      glossaryContent += "</dl>\n";
      fs.writeFileSync("".concat(this.docDir, "/Glossary.md"), glossaryContent);
    }
  }]);

  return Policies;
}(), _docDir = new WeakMap(), _roles = new WeakMap(), _rolesFile = new WeakMap(), _terms = new WeakMap(), _temp$1);

var refreshDocuments = function refreshDocuments(destDir, inputFiles) {
  var policies = new Policies();
  inputFiles.forEach(function (f) {
    return policies.addSourceFile(f);
  });
  policies.setDocumentDir(destDir);
  policies.generateDocuments();
};

exports.refreshDocuments = refreshDocuments;
//# sourceMappingURL=index.js.map
