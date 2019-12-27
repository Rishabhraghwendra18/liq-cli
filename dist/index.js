'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var fs = require('fs');

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

var _temp, _headers, _fileName, _keys, _data, _cursor;

var item = function item(keys, fields, pos) {
  if (keys.length !== fields.length) throw new Error("Found ".concat(keys.length, " keys but ").concat(fields.length, " fields."));
  var item = {
    _pos: pos
  };

  for (var i = 0; i < fields.length; i += 1) {
    item[keys[i]] = fields[i];
  }

  return item;
};

var TsvExt = (_temp =
/*#__PURE__*/
function () {
  function TsvExt(headers, keys, fileName) {
    classCallCheck(this, TsvExt);

    _headers.set(this, {
      writable: true,
      value: void 0
    });

    _fileName.set(this, {
      writable: true,
      value: void 0
    });

    _keys.set(this, {
      writable: true,
      value: void 0
    });

    _data.set(this, {
      writable: true,
      value: void 0
    });

    _cursor.set(this, {
      writable: true,
      value: void 0
    });

    this.headers = headers;
    this.fileName = fileName;
    var contents = fs.readFileSync(fileName, 'utf8'); // allow blank lines (which are ignored)

    var lines = contents.split("\n");
    lines.shift(); // remove headers line

    var filteredLines = lines.filter(function (line) {
      return !line.match(/^\s*$/);
    });
    tsv.header = false;
    this.keys = keys;
    this.data = tsv.parse(filteredLines.join("\n"));
  }

  createClass(TsvExt, [{
    key: "reset",
    value: function reset() {
      this.cursor = -1;
    }
  }, {
    key: "next",
    value: function next() {
      this.cursor += 1;
      if (this.cursor > this.length) return null;else return item(this.keys, this.data[this.cursor], this.cursor);
    }
  }, {
    key: "add",
    value: function add(item) {
      var line = [];
      this.keys.forEach(function (key) {
        var field = item[key];
        if (field === undefined) throw new Error("Item does not define key '".concat(key, "'."));
        line.push(field);
      });
      var failDesc;
      if (this.notUnique && (failDesc = this.notUnique(this.data.slice(), item))) throw new Error(failDesc);
      this.data.push(line);
    }
  }, {
    key: "remove",
    value: function remove(key) {
      var _this = this;

      var index = this.data.findIndex(function (line) {
        return _this.matchKey(line, key);
      });
      if (index >= 0) return this.data.splice(index, 1);else return null;
    }
  }, {
    key: "write",
    value: function write() {
      fs.writeFileSync(this.fileName, "".concat(this.headers.join("\t"), "\n").concat(this.data.map(function (line) {
        return line.join("\t");
      }).join("\n"), "\n"));
    }
  }, {
    key: "length",
    get: function get() {
      return this.data.length;
    }
  }]);

  return TsvExt;
}(), _headers = new WeakMap(), _fileName = new WeakMap(), _keys = new WeakMap(), _data = new WeakMap(), _cursor = new WeakMap(), _temp);

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

var _typeof_1 = createCommonjsModule(function (module) {
function _typeof2(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof2 = function _typeof2(obj) { return typeof obj; }; } else { _typeof2 = function _typeof2(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof2(obj); }

function _typeof(obj) {
  if (typeof Symbol === "function" && _typeof2(Symbol.iterator) === "symbol") {
    module.exports = _typeof = function _typeof(obj) {
      return _typeof2(obj);
    };
  } else {
    module.exports = _typeof = function _typeof(obj) {
      return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : _typeof2(obj);
    };
  }

  return _typeof(obj);
}

module.exports = _typeof;
});

function _assertThisInitialized(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

var assertThisInitialized = _assertThisInitialized;

function _possibleConstructorReturn(self, call) {
  if (call && (_typeof_1(call) === "object" || typeof call === "function")) {
    return call;
  }

  return assertThisInitialized(self);
}

var possibleConstructorReturn = _possibleConstructorReturn;

var getPrototypeOf = createCommonjsModule(function (module) {
function _getPrototypeOf(o) {
  module.exports = _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}

module.exports = _getPrototypeOf;
});

var setPrototypeOf = createCommonjsModule(function (module) {
function _setPrototypeOf(o, p) {
  module.exports = _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

module.exports = _setPrototypeOf;
});

function _inherits(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) setPrototypeOf(subClass, superClass);
}

var inherits = _inherits;

var _class, _temp$1;
var Roles = (_temp$1 = _class =
/*#__PURE__*/
function (_TsvExt) {
  inherits(Roles, _TsvExt);

  function Roles(fileName) {
    classCallCheck(this, Roles);

    return possibleConstructorReturn(this, getPrototypeOf(Roles).call(this, Roles.keys, fileName));
  }

  return Roles;
}(TsvExt), defineProperty(_class, "keys", ['name', 'application', 'superRole', 'description', 'notes']), _temp$1);

var _temp$2, _docDir, _roles, _rolesFile, _terms;
var Policies = (_temp$2 =
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
}(), _docDir = new WeakMap(), _roles = new WeakMap(), _rolesFile = new WeakMap(), _terms = new WeakMap(), _temp$2);

var refreshDocuments = function refreshDocuments(destDir, inputFiles) {
  var policies = new Policies();
  inputFiles.forEach(function (f) {
    return policies.addSourceFile(f);
  });
  policies.setDocumentDir(destDir);
  policies.generateDocuments();
};

function _classCallCheck$1(instance, Constructor) {
  if (!(instance instanceof Constructor)) {
    throw new TypeError("Cannot call a class as a function");
  }
}

var classCallCheck$1 = _classCallCheck$1;

function _defineProperties$1(target, props) {
  for (var i = 0; i < props.length; i++) {
    var descriptor = props[i];
    descriptor.enumerable = descriptor.enumerable || false;
    descriptor.configurable = true;
    if ("value" in descriptor) descriptor.writable = true;
    Object.defineProperty(target, descriptor.key, descriptor);
  }
}

function _createClass$1(Constructor, protoProps, staticProps) {
  if (protoProps) _defineProperties$1(Constructor.prototype, protoProps);
  if (staticProps) _defineProperties$1(Constructor, staticProps);
  return Constructor;
}

var createClass$1 = _createClass$1;

function createCommonjsModule$1(fn, module) {
	return module = { exports: {} }, fn(module, module.exports), module.exports;
}

var _typeof_1$1 = createCommonjsModule$1(function (module) {
function _typeof2(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof2 = function _typeof2(obj) { return typeof obj; }; } else { _typeof2 = function _typeof2(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof2(obj); }

function _typeof(obj) {
  if (typeof Symbol === "function" && _typeof2(Symbol.iterator) === "symbol") {
    module.exports = _typeof = function _typeof(obj) {
      return _typeof2(obj);
    };
  } else {
    module.exports = _typeof = function _typeof(obj) {
      return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : _typeof2(obj);
    };
  }

  return _typeof(obj);
}

module.exports = _typeof;
});

function _assertThisInitialized$1(self) {
  if (self === void 0) {
    throw new ReferenceError("this hasn't been initialised - super() hasn't been called");
  }

  return self;
}

var assertThisInitialized$1 = _assertThisInitialized$1;

function _possibleConstructorReturn$1(self, call) {
  if (call && (_typeof_1$1(call) === "object" || typeof call === "function")) {
    return call;
  }

  return assertThisInitialized$1(self);
}

var possibleConstructorReturn$1 = _possibleConstructorReturn$1;

var getPrototypeOf$1 = createCommonjsModule$1(function (module) {
function _getPrototypeOf(o) {
  module.exports = _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) {
    return o.__proto__ || Object.getPrototypeOf(o);
  };
  return _getPrototypeOf(o);
}

module.exports = _getPrototypeOf;
});

var setPrototypeOf$1 = createCommonjsModule$1(function (module) {
function _setPrototypeOf(o, p) {
  module.exports = _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) {
    o.__proto__ = p;
    return o;
  };

  return _setPrototypeOf(o, p);
}

module.exports = _setPrototypeOf;
});

function _inherits$1(subClass, superClass) {
  if (typeof superClass !== "function" && superClass !== null) {
    throw new TypeError("Super expression must either be null or a function");
  }

  subClass.prototype = Object.create(superClass && superClass.prototype, {
    constructor: {
      value: subClass,
      writable: true,
      configurable: true
    }
  });
  if (superClass) setPrototypeOf$1(subClass, superClass);
}

var inherits$1 = _inherits$1;

function _defineProperty$1(obj, key, value) {
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

var defineProperty$1 = _defineProperty$1;

var _class$1, _temp$3;
var PolicyCalendar = (_temp$3 = _class$1 =
/*#__PURE__*/
function (_TsvExt) {
  inherits$1(PolicyCalendar, _TsvExt);

  /**
  * Item Name : org wide unique calendar item name.
  * Description : Short description of calendar item.
  * Frequency : One of triennial, biennial, annual, semiannual, triannual, quarterly, bimonhtly, monthly, weekly.
  * Impact Weighting : Roughly the number of man-hours necessary to complete a task.
  * Span : Number of hours to alot for event. For 8+ hours, span is didvided by 8 and rounded up for span of days.
  */
  function PolicyCalendar(fileName) {
    var _this;

    classCallCheck$1(this, PolicyCalendar);

    _this = possibleConstructorReturn$1(this, getPrototypeOf$1(PolicyCalendar).call(this, PolicyCalendar.headers, PolicyCalendar.keys, fileName));

    defineProperty$1(assertThisInitialized$1(_this), "matchKey", function (line, key) {
      return line[0] === key;
    });

    return _this;
  }

  createClass$1(PolicyCalendar, [{
    key: "notUnique",
    value: function notUnique(data, item) {
      var i;
      return -1 !== (i = data.findIndex(function (line) {
        return line[0].toLowerCase() === item.itemName.toLowerCase();
      })) && "Policy calendar item '".concat(item.itemName, "' already exists at entry ").concat(i + 1, ".");
    }
    /**
     * Generates an iniital, balanced, concrete schedule based on the Policy calendar requirements.
     */

  }, {
    key: "schedule",
    value: function schedule() {
      var dayWeights = lib.initDayWeights();
      this.reset();
      var item;

      while (item = this.next()) {
        var monthsSets = void 0;

        switch (item.frequency) {
          case 'weekly':
          case 'monthly':
            monthsSets = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]];
            break;

          case 'bimonthly':
            monthsSets = [[0, 2, 4, 6, 8, 10], [1, 3, 5, 7, 9, 11]];
            break;

          case 'quarterly':
            monthsSets = [[0, 3, 6, 9]];
            break;

          case 'triannual':
            monthsSets = [[0, 4, 8], [1, 5, 9]];
            break;

          case 'semiannual':
            monthsSets = [[0, 6], [1, 7], [2, 8], [3, 9]];
            break;

          default:
            monthsSets = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9]];
            break;
        }

        var leastMonthsSet = lib.leastMonthsSet(dayWeights, monthsSets); // For sub-annual items, we don't try to align weeks, just months, so earch occurance will be scheduled
        // independently.

        leastMonthsSet.forEach(function (month) {
          var leastWeekOfMonth = lib.leastWeekOfMonth(dayWeights, month);
          var policyEvent = lib.scheduleInWeek(dayWeights[month * 4 + leastWeekOfMonth], item);
        });
      } // while ...this.next()

    } // schedule()

  }]);

  return PolicyCalendar;
}(TsvExt), defineProperty$1(_class$1, "headers", ['Item Name', 'Description', 'Frequency', 'Impact Weighting', 'Span']), defineProperty$1(_class$1, "keys", ['itemName', 'description', 'frequency', 'impactWeighting', 'span']), defineProperty$1(_class$1, "BIENNIAL_SELECTOR", ['ODD', 'EVEN']), defineProperty$1(_class$1, "TRIENNIAL_SELECTOR", ['ODD', 'EVEN', 'TRIPLETS']), _temp$3);

var _class$2, _temp$4;
var Staff = (_temp$4 = _class$2 =
/*#__PURE__*/
function (_TsvExt) {
  inherits$1(Staff, _TsvExt);

  function Staff(fileName) {
    var _this;

    classCallCheck$1(this, Staff);

    _this = possibleConstructorReturn$1(this, getPrototypeOf$1(Staff).call(this, Staff.headers, Staff.keys, fileName));

    defineProperty$1(assertThisInitialized$1(_this), "matchKey", function (line, key) {
      return line[0] === key;
    });

    return _this;
  }

  createClass$1(Staff, [{
    key: "notUnique",
    value: function notUnique(data, item) {
      var i;
      return -1 !== (i = data.findIndex(function (line) {
        return line[0].toLowerCase() === item.email.toLowerCase();
      })) && "Staff member with email '".concat(item.email, "' already exists at entry ").concat(i + 1, ".");
    }
  }]);

  return Staff;
}(TsvExt), defineProperty$1(_class$2, "headers", ['Email', 'Family Name', 'Given Name', 'Start Date']), defineProperty$1(_class$2, "keys", ['email', 'familyName', 'givenName', 'startDate']), _temp$4);

exports.PolicyCalendar = PolicyCalendar;
exports.Staff = Staff;
exports.refreshDocuments = refreshDocuments;
//# sourceMappingURL=index.js.map
