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
/**
 * Converts array-string data to an intermediate object. Handles the special '-' <=> null and muti-part field
 * conversions to arrays.
 */

var item = function item(keys, multis, fields, pos) {
  if (keys.length !== fields.length) throw new Error("Found ".concat(keys.length, " keys but ").concat(fields.length, " fields at item ").concat(pos, " (").concat(fields[0], ")."));
  var item = {
    _pos: pos
  };

  for (var i = 0; i < fields.length; i += 1) {
    item[keys[i]] = multis[keys[i]] ? fields[i] === '' || fields[i] === '-' ? [] : fields[i].split(/\s*,\s*/) : fields[i] === '' || fields[i] === '-' ? null : fields[i];
  }

  return item;
};

var TsvExt = (_temp =
/*#__PURE__*/
function () {
  function TsvExt(headers, keys, fileName, multis) {
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
    var contents = fs.readFileSync(fileName, 'utf8');
    var lines = contents.split("\n");
    lines.shift(); // remove headers line
    // allow blank lines (which are ignored)

    var filteredLines = lines.filter(function (line) {
      return !line.match(/^\s*$/);
    });
    tsv.header = false;
    this.keys = keys;
    this.multis = multis || {};
    this.data = filteredLines.length > 0 ? tsv.parse(filteredLines.join("\n")) : [];
  }

  createClass(TsvExt, [{
    key: "getItems",
    value: function getItems() {
      var _this = this;

      return this.data.map(function (r, i) {
        return item(_this.keys, _this.multis, r, i);
      });
    } // Adds an item as an object (NOT array)

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
      var _this2 = this;

      var index = this.data.findIndex(function (line) {
        return _this2.matchKey(line, key);
      });
      if (index >= 0) return this.data.splice(index, 1);else return null;
    }
  }, {
    key: "writeString",
    value: function writeString() {
      return "".concat(this.headers.join("\t"), "\n") + "".concat(this.data.map(function (line) {
        return line.map(function (v) {
          return v === '' || Array.isArray(v) && v.length === 0 ? '-' : v;
        }).join("\t");
      }).join("\n"), "\n");
    }
  }, {
    key: "write",
    value: function write() {
      fs.writeFileSync(this.fileName, this.writeString());
    } // Generic find; assumes the first column is the key.

  }, {
    key: "find",
    value: function find(key) {
      return this.data.find(function (line) {
        return line[0] === key;
      });
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

var AttachedRole =
/*#__PURE__*/
function () {
  function AttachedRole(baseRole, staffMember, parameters) {
    classCallCheck(this, AttachedRole);

    parameters = parameters !== undefined && parameters.split(/\s*;\s*/) || [];
    this.baseRole = baseRole;
    this.acting = parameters.some(function (p) {
      return p === 'acting';
    });
    var qualifierCapt = parameters.reduce(function (result, p) {
      return result || /qual:([^,]+)/.exec(p);
    }, null);
    this.qualifier = null;
    if (qualifierCapt) this.qualifier = qualifierCapt[1].trim();
    if (!baseRole.isQualifiable() && this.qualifier) throw new Error("Attempt to qualify non-qualifiable role '".concat(baseRole.getName(), "' ") + "for staff member '".concat(staffMember.getEmail(), "'."));
  }

  createClass(AttachedRole, [{
    key: "getName",
    value: function getName() {
      return this.baseRole.getName();
    }
  }, {
    key: "isActing",
    value: function isActing() {
      return this.acting;
    }
  }, {
    key: "isQualifiable",
    value: function isQualifiable() {
      return this.baseRole.isQualifiable();
    }
  }, {
    key: "getQualifier",
    value: function getQualifier() {
      return this.qualifier;
    }
  }]);

  return AttachedRole;
}();

var Role =
/*#__PURE__*/
function () {
  function Role(item) {
    classCallCheck(this, Role);

    this.item = item;
  }

  createClass(Role, [{
    key: "getName",
    value: function getName() {
      return this.item.name;
    }
  }, {
    key: "isQualifiable",
    value: function isQualifiable() {
      var application = this.item.application;
      return Boolean(application && application.match(/(^|;)\s*qualifiable\s*(;|$)/));
    }
  }, {
    key: "attachTo",
    value: function attachTo(staff, parameters) {
      return new AttachedRole(this, staff, parameters);
    }
  }]);

  return Role;
}();

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

var _class, _temp$1;
var RolesTsv = (_temp$1 = _class =
/*#__PURE__*/
function (_TsvExt) {
  inherits(RolesTsv, _TsvExt);

  function RolesTsv(fileName) {
    var _this;

    classCallCheck(this, RolesTsv);

    _this = possibleConstructorReturn(this, getPrototypeOf(RolesTsv).call(this, RolesTsv.headers, RolesTsv.keys, fileName));

    defineProperty(assertThisInitialized(_this), "matchKey", function (line, key) {
      return line[0] === key;
    });

    return _this;
  }

  createClass(RolesTsv, [{
    key: "notUnique",
    value: function notUnique(data, item) {
      var i;
      return -1 !== (i = data.findIndex(function (line) {
        return line[0].toLowerCase() === item.name.toLowerCase();
      })) && "Role with name '".concat(item.name, "' already exists at entry ").concat(i, ".");
    }
  }, {
    key: "hydrate",

    /**
    * Turns the 'row' data into minimal Row objects.
    */
    value: function hydrate() {
      return this.getItems().reduce(function (roles, item) {
        roles[item.name] = new Role(item);
        return roles;
      }, {});
    }
  }]);

  return RolesTsv;
}(TsvExt), defineProperty(_class, "headers", ['Name', 'Application', 'Super-role', 'Description', 'Notes']), defineProperty(_class, "keys", ['name', 'application', 'superRole', 'description', 'notes']), _temp$1);

var Staff =
/*#__PURE__*/
function () {
  function Staff(item) {
    classCallCheck(this, Staff);

    this.item = item;
    this.attachedRoles = {}; // keyed by role name

    this.managers = {}; // managers keyed by our role names

    this.reportsByReportRole = {}; // roles keyed to reports role names
  }
  /**
   * Fully defines the staff data. This is done as a static method to allow us to retrieve staff my name and cross-link
   * managers with reports. In the underlying datastructure, reports are linked to managers and not vice-a-versa, so we
   * have to pre-define the universe of staff individuals in prep for / before fully defining each..
   */


  createClass(Staff, [{
    key: "getEmail",
    value: function getEmail() {
      return this.item.email;
    }
  }, {
    key: "setEmail",
    value: function setEmail(v) {
      this.item.email = v;
    }
  }, {
    key: "getFullName",
    value: function getFullName() {
      return "".concat(this.getGivenName(), " ").concat(this.getFamilyName());
    } // TODO: i18n...

  }, {
    key: "getFamilyName",
    value: function getFamilyName() {
      return this.item.familyName;
    }
  }, {
    key: "setFamilyName",
    value: function setFamilyName(v) {
      this.item.familyName = v;
    }
  }, {
    key: "getGivenName",
    value: function getGivenName() {
      return this.item.givenName;
    }
  }, {
    key: "setGivenName",
    value: function setGivenName(v) {
      this.item.givenName = v;
    }
  }, {
    key: "getStartDate",
    value: function getStartDate() {
      return this.item.startDate;
    }
  }, {
    key: "setStartDate",
    value: function setStartDate(v) {
      this.item.startDate = v;
    }
  }, {
    key: "hasRole",
    value: function hasRole(roleName) {
      return Boolean(this.attachedRoles[roleName]);
    }
  }, {
    key: "getRoleNames",
    value: function getRoleNames() {
      return Object.keys(this.attachedRoles);
    }
  }, {
    key: "getAttachedRoleByName",
    value: function getAttachedRoleByName(roleName) {
      return this.attachedRoles[roleName];
    }
  }, {
    key: "getAttachedRoles",
    value: function getAttachedRoles() {
      return Object.values(this.attachedRoles);
    }
  }, {
    key: "getManagerByRoleName",
    value: function getManagerByRoleName(roleName) {
      return this.managers[roleName];
    }
  }, {
    key: "getManagers",
    value: function getManagers() {
      return Object.values(this.manangers);
    }
  }, {
    key: "getReportsByRoleName",
    value: function getReportsByRoleName(roleName) {
      return this.reportsByReportRole[roleName] || [];
    }
  }, {
    key: "getReports",
    value: function getReports() {
      var _this = this;

      return Object.values(this.reportsByReportRole).reduce(function (acc, reps) {
        return acc.concat(reps);
      }, []).filter(function (rep) {
        return rep.getEmail() !== _this.getEmail();
      });
    }
  }], [{
    key: "hydrate",
    value: function hydrate(org) {
      Object.values(org.staff).forEach(function (s) {
        s.item.primaryRoles.forEach(function (rSpec) {
          var _rSpec$split = rSpec.split(/\//),
              _rSpec$split2 = slicedToArray(_rSpec$split, 3),
              roleName = _rSpec$split2[0],
              roleManagerEmail = _rSpec$split2[1],
              roleParameters = _rSpec$split2[2]; // verify good roleName


          var orgNode = org.orgStructure.getNodeByRoleName(roleName);
          if (orgNode === undefined) throw new Error("Staff '".concat(s.getEmail(), "' claims non-existent role '").concat(roleName, "'.")); // attach the role

          s.attachedRoles[roleName] = org.roles[roleName].attachTo(s, roleParameters); // TODO: migrate the manager to the AttachedRole
          // set manager and add ourselves to their reports

          if (orgNode.getPrimMngr() !== null) {
            var roleManager = org.getStaffMember(roleManagerEmail);
            if (roleManager === undefined) throw new Error("No such manager '".concat(roleManagerEmail, "' found while loading staff member '").concat(s.getEmail(), "'."));
            s.managers[roleName] = roleManager;
            if (roleManager.reportsByReportRole[roleName] === undefined) roleManager.reportsByReportRole[roleName] = [];
            roleManager.reportsByReportRole[roleName].push(s);
          } else s.managers[roleName] = null;
        });
      });
    }
  }]);

  return Staff;
}();

var _class$1, _temp$2;
var StaffTsv = (_temp$2 = _class$1 =
/*#__PURE__*/
function (_TsvExt) {
  inherits(StaffTsv, _TsvExt);

  function StaffTsv(fileName) {
    var _this;

    classCallCheck(this, StaffTsv);

    _this = possibleConstructorReturn(this, getPrototypeOf(StaffTsv).call(this, StaffTsv.headers, StaffTsv.keys, fileName, StaffTsv.multis));

    defineProperty(assertThisInitialized(_this), "matchKey", function (line, key) {
      return line[0] === key;
    });

    return _this;
  }

  createClass(StaffTsv, [{
    key: "init",
    value: function init() {
      return this.getItems().reduce(function (staff, item) {
        if (staff[item.email] !== undefined) throw new Error("member with email '".concat(item.email, "' already exists at entry ").concat(item._pos + 1, "."));
        staff[item.email] = new Staff(item);
        return staff;
      }, {});
    }
  }]);

  return StaffTsv;
}(TsvExt), defineProperty(_class$1, "headers", ['Email', 'Family Name', 'Given Name', 'Start Date', 'Primary Roles', 'Secondary Roles']), defineProperty(_class$1, "keys", ['email', 'familyName', 'givenName', 'startDate', 'primaryRoles', 'secondaryRoles']), defineProperty(_class$1, "multis", {
  'primaryRoles': true,
  'secondaryRoles': true,
  'managers': true
}), _temp$2);

var _class$2, _temp$3;
var PolicyCalendar = (_temp$3 = _class$2 =
/*#__PURE__*/
function (_TsvExt) {
  inherits(PolicyCalendar, _TsvExt);

  /**
  * Item Name : org wide unique calendar item name.
  * Description : Short description of calendar item.
  * Frequency : One of triennial, biennial, annual, semiannual, triannual, quarterly, bimonhtly, monthly, weekly.
  * Impact Weighting : Roughly the number of man-hours necessary to complete a task.
  * Span : Number of hours to alot for event. For 8+ hours, span is didvided by 8 and rounded up for span of days.
  */
  function PolicyCalendar(fileName) {
    var _this;

    classCallCheck(this, PolicyCalendar);

    _this = possibleConstructorReturn(this, getPrototypeOf(PolicyCalendar).call(this, PolicyCalendar.headers, PolicyCalendar.keys, fileName));

    defineProperty(assertThisInitialized(_this), "matchKey", function (line, key) {
      return line[0] === key;
    });

    return _this;
  }

  createClass(PolicyCalendar, [{
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
}(TsvExt), defineProperty(_class$2, "headers", ['UUID', 'Item Name', 'Description', 'Frequency', 'Impact Weighting (hrs)', 'Time Span (days)', 'Absolute Condition', 'Policy Refs']), defineProperty(_class$2, "keys", ['uuid', 'itemName', 'description', 'frequency', 'impactWeighting', 'timeSpan', 'absCond', 'policyRefs']), defineProperty(_class$2, "BIENNIAL_SELECTOR", ['ODD', 'EVEN']), defineProperty(_class$2, "TRIENNIAL_SELECTOR", ['ODD', 'EVEN', 'TRIPLETS']), _temp$3);

var Glossary =
/*#__PURE__*/
function () {
  function Glossary() {
    classCallCheck(this, Glossary);

    this.terms = [];
  }

  createClass(Glossary, [{
    key: "addTerm",
    value: function addTerm(term, definition) {
      this.terms.push([term, definition]);
    }
  }, {
    key: "addTermsFromIterator",
    value: function addTermsFromIterator(_ref) {
      var it = _ref.it,
          _ref$termKey = _ref.termKey,
          termKey = _ref$termKey === void 0 ? 'name' : _ref$termKey,
          _ref$descKey = _ref.descKey,
          descKey = _ref$descKey === void 0 ? 'description' : _ref$descKey;
      if (!it) return;
      it.reset();
      var i;

      while (i = it.next()) {
        this.addTerm(i[termKey], i[descKey]);
      }
    }
  }, {
    key: "generateContent",
    value: function generateContent() {
      var content = "# Glossary\n\n<dl>";
      this.terms.sort(function (a, b) {
        return a[0].localeCompare(b[0]);
      });
      this.terms.forEach(function (_ref2) {
        var _ref3 = slicedToArray(_ref2, 2),
            term = _ref3[0],
            def = _ref3[1];

        return content += "  <dt>".concat(term, "</dt>\n  <dd>").concat(def, "</dd>\n\n");
      });
      content += "</dl>\n";
      return content;
    }
  }]);

  return Glossary;
}();

var _temp$4, _docDir, _roles, _rolesFile, _terms;
var Policies = (_temp$4 =
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
      if (this.roles !== undefined) return this.roles; // TODO: allom multiple role files to be merged

      var rolesFile = this.findFile(this.rolesFile);
      this.roles = new RolesTsv(rolesFile);
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
    key: "setDocumentDir",
    value: function setDocumentDir(dir) {
      this.docDir = dir;
    }
  }, {
    key: "generateDocuments",
    value: function generateDocuments() {
      if (this.docDir === undefined) throw new Error('No document directory defined.');
      if (!fs.existsSync(this.docDir)) throw new Error("Target document dir '".concat(this.docDir, "' does not exist."));
      var roles = this.getRoles();
      var glossary = new Glossary();
      if (roles) glossary.addTermsFromIterator(roles); // TODO: else warn

      fs.writeFileSync("".concat(this.docDir, "/Glossary.md"), glossary.generateContent());
    }
  }]);

  return Policies;
}(), _docDir = new WeakMap(), _roles = new WeakMap(), _rolesFile = new WeakMap(), _terms = new WeakMap(), _temp$4);

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
