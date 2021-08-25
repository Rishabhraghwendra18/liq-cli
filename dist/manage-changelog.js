'use strict';

var dateFormat = require('dateformat');
var fs = require('fs');
var YAML = require('yaml');
var simpleGit = require('simple-git');

function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

function _interopNamespace(e) {
  if (e && e.__esModule) return e;
  var n = Object.create(null);
  if (e) {
    Object.keys(e).forEach(function (k) {
      if (k !== 'default') {
        var d = Object.getOwnPropertyDescriptor(e, k);
        Object.defineProperty(n, k, d.get ? d : {
          enumerable: true,
          get: function () {
            return e[k];
          }
        });
      }
    });
  }
  n['default'] = e;
  return Object.freeze(n);
}

var dateFormat__default = /*#__PURE__*/_interopDefaultLegacy(dateFormat);
var fs__namespace = /*#__PURE__*/_interopNamespace(fs);
var YAML__default = /*#__PURE__*/_interopDefaultLegacy(YAML);
var simpleGit__default = /*#__PURE__*/_interopDefaultLegacy(simpleGit);

var readChangelog = function readChangelog() {
  var clPathish = requireEnv('CHANGELOG_FILE');
  var clPath = clPathish === '-' ? 0 : clPathish;
  var changelogContents = fs__namespace.readFileSync(clPath, 'utf8'); // include encoding to get 'string' result

  var changelog = YAML__default['default'].parse(changelogContents);
  return changelog;
};

var requireEnv = function requireEnv(key) {
  return process.env[key] || function (e) {
    throw e;
  }(new Error("Did not find required environment parameter: ".concat(key)));
};

var saveChangelog = function saveChangelog(changelog) {
  var clPath = requireEnv('CHANGELOG_FILE');
  var changelogContents = YAML__default['default'].stringify(changelog);
  fs__namespace.writeFileSync(clPath, changelogContents);
};

var createNewEntry = function createNewEntry(changelog) {
  // get the approx start time according to the local clock
  var now = new Date();
  var startTimestamp = dateFormat__default['default'](now, 'UTC:yyyy-mm-dd-HHMM.ss Z');
  var startEpochMillis = now.now(); // process the 'work unit' data

  var issues = requireEnv('WORK_ISSUES').split('\n');
  var involvedProjects = requireEnv('INVOLVED_PROJECTS').split('\n');
  var newEntry = {
    startTimestamp: startTimestamp,
    startEpochMillis: startEpochMillis,
    issues: issues,
    branch: requireEnv('WORK_BRANCH'),
    branchFrom: requireEnv('CURR_REPO_VERSION'),
    workInitiator: requireEnv('WORK_INITIATOR'),
    branchInitiator: requireEnv('CURR_USER'),
    involvedProjects: involvedProjects,
    changeNotes: [requireEnv('WORK_DESC')],
    securityNotes: [],
    drpBcpNotes: [],
    backoutNotes: []
  };
  changelog.push(newEntry);
  return newEntry;
};

var addEntry = function addEntry() {
  var changelog = readChangelog();
  createNewEntry(changelog);
  saveChangelog(changelog);
};

function unwrapExports (x) {
	return x && x.__esModule && Object.prototype.hasOwnProperty.call(x, 'default') ? x['default'] : x;
}

function createCommonjsModule(fn, module) {
	return module = { exports: {} }, fn(module, module.exports), module.exports;
}

var asyncToGenerator = createCommonjsModule(function (module) {
function asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) {
  try {
    var info = gen[key](arg);
    var value = info.value;
  } catch (error) {
    reject(error);
    return;
  }

  if (info.done) {
    resolve(value);
  } else {
    Promise.resolve(value).then(_next, _throw);
  }
}

function _asyncToGenerator(fn) {
  return function () {
    var self = this,
        args = arguments;
    return new Promise(function (resolve, reject) {
      var gen = fn.apply(self, args);

      function _next(value) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value);
      }

      function _throw(err) {
        asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err);
      }

      _next(undefined);
    });
  };
}

module.exports = _asyncToGenerator;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

var _asyncToGenerator = unwrapExports(asyncToGenerator);

var runtime_1 = createCommonjsModule(function (module) {
/**
 * Copyright (c) 2014-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

var runtime = (function (exports) {

  var Op = Object.prototype;
  var hasOwn = Op.hasOwnProperty;
  var undefined$1; // More compressible than void 0.
  var $Symbol = typeof Symbol === "function" ? Symbol : {};
  var iteratorSymbol = $Symbol.iterator || "@@iterator";
  var asyncIteratorSymbol = $Symbol.asyncIterator || "@@asyncIterator";
  var toStringTagSymbol = $Symbol.toStringTag || "@@toStringTag";

  function define(obj, key, value) {
    Object.defineProperty(obj, key, {
      value: value,
      enumerable: true,
      configurable: true,
      writable: true
    });
    return obj[key];
  }
  try {
    // IE 8 has a broken Object.defineProperty that only works on DOM objects.
    define({}, "");
  } catch (err) {
    define = function(obj, key, value) {
      return obj[key] = value;
    };
  }

  function wrap(innerFn, outerFn, self, tryLocsList) {
    // If outerFn provided and outerFn.prototype is a Generator, then outerFn.prototype instanceof Generator.
    var protoGenerator = outerFn && outerFn.prototype instanceof Generator ? outerFn : Generator;
    var generator = Object.create(protoGenerator.prototype);
    var context = new Context(tryLocsList || []);

    // The ._invoke method unifies the implementations of the .next,
    // .throw, and .return methods.
    generator._invoke = makeInvokeMethod(innerFn, self, context);

    return generator;
  }
  exports.wrap = wrap;

  // Try/catch helper to minimize deoptimizations. Returns a completion
  // record like context.tryEntries[i].completion. This interface could
  // have been (and was previously) designed to take a closure to be
  // invoked without arguments, but in all the cases we care about we
  // already have an existing method we want to call, so there's no need
  // to create a new function object. We can even get away with assuming
  // the method takes exactly one argument, since that happens to be true
  // in every case, so we don't have to touch the arguments object. The
  // only additional allocation required is the completion record, which
  // has a stable shape and so hopefully should be cheap to allocate.
  function tryCatch(fn, obj, arg) {
    try {
      return { type: "normal", arg: fn.call(obj, arg) };
    } catch (err) {
      return { type: "throw", arg: err };
    }
  }

  var GenStateSuspendedStart = "suspendedStart";
  var GenStateSuspendedYield = "suspendedYield";
  var GenStateExecuting = "executing";
  var GenStateCompleted = "completed";

  // Returning this object from the innerFn has the same effect as
  // breaking out of the dispatch switch statement.
  var ContinueSentinel = {};

  // Dummy constructor functions that we use as the .constructor and
  // .constructor.prototype properties for functions that return Generator
  // objects. For full spec compliance, you may wish to configure your
  // minifier not to mangle the names of these two functions.
  function Generator() {}
  function GeneratorFunction() {}
  function GeneratorFunctionPrototype() {}

  // This is a polyfill for %IteratorPrototype% for environments that
  // don't natively support it.
  var IteratorPrototype = {};
  IteratorPrototype[iteratorSymbol] = function () {
    return this;
  };

  var getProto = Object.getPrototypeOf;
  var NativeIteratorPrototype = getProto && getProto(getProto(values([])));
  if (NativeIteratorPrototype &&
      NativeIteratorPrototype !== Op &&
      hasOwn.call(NativeIteratorPrototype, iteratorSymbol)) {
    // This environment has a native %IteratorPrototype%; use it instead
    // of the polyfill.
    IteratorPrototype = NativeIteratorPrototype;
  }

  var Gp = GeneratorFunctionPrototype.prototype =
    Generator.prototype = Object.create(IteratorPrototype);
  GeneratorFunction.prototype = Gp.constructor = GeneratorFunctionPrototype;
  GeneratorFunctionPrototype.constructor = GeneratorFunction;
  GeneratorFunction.displayName = define(
    GeneratorFunctionPrototype,
    toStringTagSymbol,
    "GeneratorFunction"
  );

  // Helper for defining the .next, .throw, and .return methods of the
  // Iterator interface in terms of a single ._invoke method.
  function defineIteratorMethods(prototype) {
    ["next", "throw", "return"].forEach(function(method) {
      define(prototype, method, function(arg) {
        return this._invoke(method, arg);
      });
    });
  }

  exports.isGeneratorFunction = function(genFun) {
    var ctor = typeof genFun === "function" && genFun.constructor;
    return ctor
      ? ctor === GeneratorFunction ||
        // For the native GeneratorFunction constructor, the best we can
        // do is to check its .name property.
        (ctor.displayName || ctor.name) === "GeneratorFunction"
      : false;
  };

  exports.mark = function(genFun) {
    if (Object.setPrototypeOf) {
      Object.setPrototypeOf(genFun, GeneratorFunctionPrototype);
    } else {
      genFun.__proto__ = GeneratorFunctionPrototype;
      define(genFun, toStringTagSymbol, "GeneratorFunction");
    }
    genFun.prototype = Object.create(Gp);
    return genFun;
  };

  // Within the body of any async function, `await x` is transformed to
  // `yield regeneratorRuntime.awrap(x)`, so that the runtime can test
  // `hasOwn.call(value, "__await")` to determine if the yielded value is
  // meant to be awaited.
  exports.awrap = function(arg) {
    return { __await: arg };
  };

  function AsyncIterator(generator, PromiseImpl) {
    function invoke(method, arg, resolve, reject) {
      var record = tryCatch(generator[method], generator, arg);
      if (record.type === "throw") {
        reject(record.arg);
      } else {
        var result = record.arg;
        var value = result.value;
        if (value &&
            typeof value === "object" &&
            hasOwn.call(value, "__await")) {
          return PromiseImpl.resolve(value.__await).then(function(value) {
            invoke("next", value, resolve, reject);
          }, function(err) {
            invoke("throw", err, resolve, reject);
          });
        }

        return PromiseImpl.resolve(value).then(function(unwrapped) {
          // When a yielded Promise is resolved, its final value becomes
          // the .value of the Promise<{value,done}> result for the
          // current iteration.
          result.value = unwrapped;
          resolve(result);
        }, function(error) {
          // If a rejected Promise was yielded, throw the rejection back
          // into the async generator function so it can be handled there.
          return invoke("throw", error, resolve, reject);
        });
      }
    }

    var previousPromise;

    function enqueue(method, arg) {
      function callInvokeWithMethodAndArg() {
        return new PromiseImpl(function(resolve, reject) {
          invoke(method, arg, resolve, reject);
        });
      }

      return previousPromise =
        // If enqueue has been called before, then we want to wait until
        // all previous Promises have been resolved before calling invoke,
        // so that results are always delivered in the correct order. If
        // enqueue has not been called before, then it is important to
        // call invoke immediately, without waiting on a callback to fire,
        // so that the async generator function has the opportunity to do
        // any necessary setup in a predictable way. This predictability
        // is why the Promise constructor synchronously invokes its
        // executor callback, and why async functions synchronously
        // execute code before the first await. Since we implement simple
        // async functions in terms of async generators, it is especially
        // important to get this right, even though it requires care.
        previousPromise ? previousPromise.then(
          callInvokeWithMethodAndArg,
          // Avoid propagating failures to Promises returned by later
          // invocations of the iterator.
          callInvokeWithMethodAndArg
        ) : callInvokeWithMethodAndArg();
    }

    // Define the unified helper method that is used to implement .next,
    // .throw, and .return (see defineIteratorMethods).
    this._invoke = enqueue;
  }

  defineIteratorMethods(AsyncIterator.prototype);
  AsyncIterator.prototype[asyncIteratorSymbol] = function () {
    return this;
  };
  exports.AsyncIterator = AsyncIterator;

  // Note that simple async functions are implemented on top of
  // AsyncIterator objects; they just return a Promise for the value of
  // the final result produced by the iterator.
  exports.async = function(innerFn, outerFn, self, tryLocsList, PromiseImpl) {
    if (PromiseImpl === void 0) PromiseImpl = Promise;

    var iter = new AsyncIterator(
      wrap(innerFn, outerFn, self, tryLocsList),
      PromiseImpl
    );

    return exports.isGeneratorFunction(outerFn)
      ? iter // If outerFn is a generator, return the full iterator.
      : iter.next().then(function(result) {
          return result.done ? result.value : iter.next();
        });
  };

  function makeInvokeMethod(innerFn, self, context) {
    var state = GenStateSuspendedStart;

    return function invoke(method, arg) {
      if (state === GenStateExecuting) {
        throw new Error("Generator is already running");
      }

      if (state === GenStateCompleted) {
        if (method === "throw") {
          throw arg;
        }

        // Be forgiving, per 25.3.3.3.3 of the spec:
        // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-generatorresume
        return doneResult();
      }

      context.method = method;
      context.arg = arg;

      while (true) {
        var delegate = context.delegate;
        if (delegate) {
          var delegateResult = maybeInvokeDelegate(delegate, context);
          if (delegateResult) {
            if (delegateResult === ContinueSentinel) continue;
            return delegateResult;
          }
        }

        if (context.method === "next") {
          // Setting context._sent for legacy support of Babel's
          // function.sent implementation.
          context.sent = context._sent = context.arg;

        } else if (context.method === "throw") {
          if (state === GenStateSuspendedStart) {
            state = GenStateCompleted;
            throw context.arg;
          }

          context.dispatchException(context.arg);

        } else if (context.method === "return") {
          context.abrupt("return", context.arg);
        }

        state = GenStateExecuting;

        var record = tryCatch(innerFn, self, context);
        if (record.type === "normal") {
          // If an exception is thrown from innerFn, we leave state ===
          // GenStateExecuting and loop back for another invocation.
          state = context.done
            ? GenStateCompleted
            : GenStateSuspendedYield;

          if (record.arg === ContinueSentinel) {
            continue;
          }

          return {
            value: record.arg,
            done: context.done
          };

        } else if (record.type === "throw") {
          state = GenStateCompleted;
          // Dispatch the exception by looping back around to the
          // context.dispatchException(context.arg) call above.
          context.method = "throw";
          context.arg = record.arg;
        }
      }
    };
  }

  // Call delegate.iterator[context.method](context.arg) and handle the
  // result, either by returning a { value, done } result from the
  // delegate iterator, or by modifying context.method and context.arg,
  // setting context.delegate to null, and returning the ContinueSentinel.
  function maybeInvokeDelegate(delegate, context) {
    var method = delegate.iterator[context.method];
    if (method === undefined$1) {
      // A .throw or .return when the delegate iterator has no .throw
      // method always terminates the yield* loop.
      context.delegate = null;

      if (context.method === "throw") {
        // Note: ["return"] must be used for ES3 parsing compatibility.
        if (delegate.iterator["return"]) {
          // If the delegate iterator has a return method, give it a
          // chance to clean up.
          context.method = "return";
          context.arg = undefined$1;
          maybeInvokeDelegate(delegate, context);

          if (context.method === "throw") {
            // If maybeInvokeDelegate(context) changed context.method from
            // "return" to "throw", let that override the TypeError below.
            return ContinueSentinel;
          }
        }

        context.method = "throw";
        context.arg = new TypeError(
          "The iterator does not provide a 'throw' method");
      }

      return ContinueSentinel;
    }

    var record = tryCatch(method, delegate.iterator, context.arg);

    if (record.type === "throw") {
      context.method = "throw";
      context.arg = record.arg;
      context.delegate = null;
      return ContinueSentinel;
    }

    var info = record.arg;

    if (! info) {
      context.method = "throw";
      context.arg = new TypeError("iterator result is not an object");
      context.delegate = null;
      return ContinueSentinel;
    }

    if (info.done) {
      // Assign the result of the finished delegate to the temporary
      // variable specified by delegate.resultName (see delegateYield).
      context[delegate.resultName] = info.value;

      // Resume execution at the desired location (see delegateYield).
      context.next = delegate.nextLoc;

      // If context.method was "throw" but the delegate handled the
      // exception, let the outer generator proceed normally. If
      // context.method was "next", forget context.arg since it has been
      // "consumed" by the delegate iterator. If context.method was
      // "return", allow the original .return call to continue in the
      // outer generator.
      if (context.method !== "return") {
        context.method = "next";
        context.arg = undefined$1;
      }

    } else {
      // Re-yield the result returned by the delegate method.
      return info;
    }

    // The delegate iterator is finished, so forget it and continue with
    // the outer generator.
    context.delegate = null;
    return ContinueSentinel;
  }

  // Define Generator.prototype.{next,throw,return} in terms of the
  // unified ._invoke helper method.
  defineIteratorMethods(Gp);

  define(Gp, toStringTagSymbol, "Generator");

  // A Generator should always return itself as the iterator object when the
  // @@iterator function is called on it. Some browsers' implementations of the
  // iterator prototype chain incorrectly implement this, causing the Generator
  // object to not be returned from this call. This ensures that doesn't happen.
  // See https://github.com/facebook/regenerator/issues/274 for more details.
  Gp[iteratorSymbol] = function() {
    return this;
  };

  Gp.toString = function() {
    return "[object Generator]";
  };

  function pushTryEntry(locs) {
    var entry = { tryLoc: locs[0] };

    if (1 in locs) {
      entry.catchLoc = locs[1];
    }

    if (2 in locs) {
      entry.finallyLoc = locs[2];
      entry.afterLoc = locs[3];
    }

    this.tryEntries.push(entry);
  }

  function resetTryEntry(entry) {
    var record = entry.completion || {};
    record.type = "normal";
    delete record.arg;
    entry.completion = record;
  }

  function Context(tryLocsList) {
    // The root entry object (effectively a try statement without a catch
    // or a finally block) gives us a place to store values thrown from
    // locations where there is no enclosing try statement.
    this.tryEntries = [{ tryLoc: "root" }];
    tryLocsList.forEach(pushTryEntry, this);
    this.reset(true);
  }

  exports.keys = function(object) {
    var keys = [];
    for (var key in object) {
      keys.push(key);
    }
    keys.reverse();

    // Rather than returning an object with a next method, we keep
    // things simple and return the next function itself.
    return function next() {
      while (keys.length) {
        var key = keys.pop();
        if (key in object) {
          next.value = key;
          next.done = false;
          return next;
        }
      }

      // To avoid creating an additional object, we just hang the .value
      // and .done properties off the next function object itself. This
      // also ensures that the minifier will not anonymize the function.
      next.done = true;
      return next;
    };
  };

  function values(iterable) {
    if (iterable) {
      var iteratorMethod = iterable[iteratorSymbol];
      if (iteratorMethod) {
        return iteratorMethod.call(iterable);
      }

      if (typeof iterable.next === "function") {
        return iterable;
      }

      if (!isNaN(iterable.length)) {
        var i = -1, next = function next() {
          while (++i < iterable.length) {
            if (hasOwn.call(iterable, i)) {
              next.value = iterable[i];
              next.done = false;
              return next;
            }
          }

          next.value = undefined$1;
          next.done = true;

          return next;
        };

        return next.next = next;
      }
    }

    // Return an iterator with no values.
    return { next: doneResult };
  }
  exports.values = values;

  function doneResult() {
    return { value: undefined$1, done: true };
  }

  Context.prototype = {
    constructor: Context,

    reset: function(skipTempReset) {
      this.prev = 0;
      this.next = 0;
      // Resetting context._sent for legacy support of Babel's
      // function.sent implementation.
      this.sent = this._sent = undefined$1;
      this.done = false;
      this.delegate = null;

      this.method = "next";
      this.arg = undefined$1;

      this.tryEntries.forEach(resetTryEntry);

      if (!skipTempReset) {
        for (var name in this) {
          // Not sure about the optimal order of these conditions:
          if (name.charAt(0) === "t" &&
              hasOwn.call(this, name) &&
              !isNaN(+name.slice(1))) {
            this[name] = undefined$1;
          }
        }
      }
    },

    stop: function() {
      this.done = true;

      var rootEntry = this.tryEntries[0];
      var rootRecord = rootEntry.completion;
      if (rootRecord.type === "throw") {
        throw rootRecord.arg;
      }

      return this.rval;
    },

    dispatchException: function(exception) {
      if (this.done) {
        throw exception;
      }

      var context = this;
      function handle(loc, caught) {
        record.type = "throw";
        record.arg = exception;
        context.next = loc;

        if (caught) {
          // If the dispatched exception was caught by a catch block,
          // then let that catch block handle the exception normally.
          context.method = "next";
          context.arg = undefined$1;
        }

        return !! caught;
      }

      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        var record = entry.completion;

        if (entry.tryLoc === "root") {
          // Exception thrown outside of any try block that could handle
          // it, so set the completion value of the entire function to
          // throw the exception.
          return handle("end");
        }

        if (entry.tryLoc <= this.prev) {
          var hasCatch = hasOwn.call(entry, "catchLoc");
          var hasFinally = hasOwn.call(entry, "finallyLoc");

          if (hasCatch && hasFinally) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            } else if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else if (hasCatch) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            }

          } else if (hasFinally) {
            if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else {
            throw new Error("try statement without catch or finally");
          }
        }
      }
    },

    abrupt: function(type, arg) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc <= this.prev &&
            hasOwn.call(entry, "finallyLoc") &&
            this.prev < entry.finallyLoc) {
          var finallyEntry = entry;
          break;
        }
      }

      if (finallyEntry &&
          (type === "break" ||
           type === "continue") &&
          finallyEntry.tryLoc <= arg &&
          arg <= finallyEntry.finallyLoc) {
        // Ignore the finally entry if control is not jumping to a
        // location outside the try/catch block.
        finallyEntry = null;
      }

      var record = finallyEntry ? finallyEntry.completion : {};
      record.type = type;
      record.arg = arg;

      if (finallyEntry) {
        this.method = "next";
        this.next = finallyEntry.finallyLoc;
        return ContinueSentinel;
      }

      return this.complete(record);
    },

    complete: function(record, afterLoc) {
      if (record.type === "throw") {
        throw record.arg;
      }

      if (record.type === "break" ||
          record.type === "continue") {
        this.next = record.arg;
      } else if (record.type === "return") {
        this.rval = this.arg = record.arg;
        this.method = "return";
        this.next = "end";
      } else if (record.type === "normal" && afterLoc) {
        this.next = afterLoc;
      }

      return ContinueSentinel;
    },

    finish: function(finallyLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.finallyLoc === finallyLoc) {
          this.complete(entry.completion, entry.afterLoc);
          resetTryEntry(entry);
          return ContinueSentinel;
        }
      }
    },

    "catch": function(tryLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc === tryLoc) {
          var record = entry.completion;
          if (record.type === "throw") {
            var thrown = record.arg;
            resetTryEntry(entry);
          }
          return thrown;
        }
      }

      // The context.catch method must only be called with a location
      // argument that corresponds to a known catch block.
      throw new Error("illegal catch attempt");
    },

    delegateYield: function(iterable, resultName, nextLoc) {
      this.delegate = {
        iterator: values(iterable),
        resultName: resultName,
        nextLoc: nextLoc
      };

      if (this.method === "next") {
        // Deliberately forget the last sent value so that we don't
        // accidentally pass it on to the delegate.
        this.arg = undefined$1;
      }

      return ContinueSentinel;
    }
  };

  // Regardless of whether this script is executing as a CommonJS module
  // or not, return the runtime object so that we can declare the variable
  // regeneratorRuntime in the outer scope, which allows this module to be
  // injected easily by `bin/regenerator --include-runtime script.js`.
  return exports;

}(
  // If this script is executing as a CommonJS module, use module.exports
  // as the regeneratorRuntime namespace. Otherwise create a new empty
  // object. Either way, the resulting object will be used to initialize
  // the regeneratorRuntime variable at the top of this file.
  module.exports 
));

try {
  regeneratorRuntime = runtime;
} catch (accidentalStrictMode) {
  // This module should not be running in strict mode, so the above
  // assignment should always work unless something is misconfigured. Just
  // in case runtime.js accidentally runs in strict mode, we can escape
  // strict mode using a global Function call. This could conceivably fail
  // if a Content Security Policy forbids using Function, but in that case
  // the proper solution is to fix the accidental strict mode problem. If
  // you've misconfigured your bundler to force strict mode and applied a
  // CSP to forbid Function, and you're not willing to fix either of those
  // problems, please detail your unique predicament in a GitHub issue.
  Function("r", "regeneratorRuntime = r")(runtime);
}
});

var regenerator = runtime_1;

var finalizeCurrentEntry = /*#__PURE__*/function () {
  var _ref = _asyncToGenerator( /*#__PURE__*/regenerator.mark(function _callee(changelog) {
    var currentEntry, involvedProjects, branchFrom, gitOptions, git, results, contributors;
    return regenerator.wrap(function _callee$(_context) {
      while (1) {
        switch (_context.prev = _context.next) {
          case 0:
            currentEntry = changelog[0]; // update the involved projects

            involvedProjects = requireEnv('INVOLVED_PROJECTS').split('\n');
            currentEntry.involvedProjects = involvedProjects;
            branchFrom = currentEntry.branchFrom;
            gitOptions = {
              baseDir: process.cwd(),
              binary: 'git',
              maxConcurrentProcesses: 6
            };
            git = simpleGit__default['default'](gitOptions);
            _context.next = 8;
            return git.raw('shortlog', '--summary', '--email', "".concat(branchFrom, "...HEAD"));

          case 8:
            results = _context.sent;
            contributors = results.split('\n').map(function (l) {
              return l.replace(/^[\s\d]+\s+/, '');
            }).filter(function (l) {
              return l.length > 0;
            });
            currentEntry.contributors = contributors;
            /*
            "qa": {
               "testedVersion": "bf820e318...",
               "unitTestReport": "https://...",
               "lintReport": "https://..."
            }
            */

            return _context.abrupt("return", currentEntry);

          case 12:
          case "end":
            return _context.stop();
        }
      }
    }, _callee);
  }));

  return function finalizeCurrentEntry(_x) {
    return _ref.apply(this, arguments);
  };
}();

var finalizeChangelog = /*#__PURE__*/function () {
  var _ref2 = _asyncToGenerator( /*#__PURE__*/regenerator.mark(function _callee2() {
    var changelog;
    return regenerator.wrap(function _callee2$(_context2) {
      while (1) {
        switch (_context2.prev = _context2.next) {
          case 0:
            changelog = readChangelog();
            _context2.next = 3;
            return finalizeCurrentEntry(changelog);

          case 3:
            saveChangelog(changelog);

          case 4:
          case "end":
            return _context2.stop();
        }
      }
    }, _callee2);
  }));

  return function finalizeChangelog() {
    return _ref2.apply(this, arguments);
  };
}();

function _createForOfIteratorHelper$1(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray$1(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }

function _unsupportedIterableToArray$1(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray$1(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray$1(o, minLen); }

function _arrayLikeToArray$1(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var printEntries = function printEntries(hotfixes, lastReleaseDate) {
  var _packageData$liq, _packageData$liq$cont, _packageData$liq2, _packageData$liq2$con;

  var changelog = readChangelog(); // TODO: this is a bit of a limitation requiring the script pwd to be the package root.

  var packageContents = fs__namespace.readFileSync('package.json');
  var packageData = JSON.parse(packageContents);
  var changeEntries = changelog.map(function (r) {
    return {
      time: new Date(r.startTimestamp),
      notes: r.changeNotes,
      author: r.workInitiator
    };
  }).concat(hotfixes.map(function (r) {
    return {
      time: new Date(r.date),
      notes: [r.message.replace(/^\s*hotfix\s*:?\s*/i, '')],
      author: r.author.email,
      isHotfix: true
    };
  })).filter(function (r) {
    return r.time >= lastReleaseDate;
  }); // with Dates, we really want '==', not '==='

  changeEntries.sort(function (a, b) {
    return a.time < b.time ? -1 : a.time == b.time ? 0 : 1;
  }); // eslint-disable-line eqeqeq

  var securityNotes = [];
  var drpBcpNotes = [];
  var backoutNotes = [];

  var _iterator = _createForOfIteratorHelper$1(changelog),
      _step;

  try {
    for (_iterator.s(); !(_step = _iterator.n()).done;) {
      var entry = _step.value;

      if (entry.securityNotes !== undefined) {
        securityNotes = securityNotes.concat(entry.securityNotes);
      }

      if (entry.drpBcpNotes !== undefined) {
        drpBcpNotes = drpBcpNotes.concat(entry.drpBcpNotes);
      }

      if (entry.backoutNotes !== undefined) {
        backoutNotes = backoutNotes.concat(entry.backoutNotes);
      }
    }
  } catch (err) {
    _iterator.e(err);
  } finally {
    _iterator.f();
  }

  var attrib = function attrib(entry) {
    return "_(".concat(entry.author, "; ").concat(entry.time.toISOString(), ")_");
  };

  var _iterator2 = _createForOfIteratorHelper$1(changeEntries),
      _step2;

  try {
    for (_iterator2.s(); !(_step2 = _iterator2.n()).done;) {
      var _entry = _step2.value;

      if (_entry.isHotfix) {
        console.log("* _**hotfix**_: ".concat(_entry.notes[0], " ").concat(attrib(_entry)));
      } else {
        var _iterator3 = _createForOfIteratorHelper$1(_entry.notes),
            _step3;

        try {
          for (_iterator3.s(); !(_step3 = _iterator3.n()).done;) {
            var note = _step3.value;
            console.log("* ".concat(note, " ").concat(attrib(_entry)));
          }
        } catch (err) {
          _iterator3.e(err);
        } finally {
          _iterator3.f();
        }
      }
    }
  } catch (err) {
    _iterator2.e(err);
  } finally {
    _iterator2.f();
  }

  if (packageData !== null && packageData !== void 0 && (_packageData$liq = packageData.liq) !== null && _packageData$liq !== void 0 && (_packageData$liq$cont = _packageData$liq.contracts) !== null && _packageData$liq$cont !== void 0 && _packageData$liq$cont.secure || securityNotes.length > 0) {
    console.log('\n### Security notes\n\n');
    console.log("".concat(securityNotes.length === 0 ? '_none_' : "* ".concat(securityNotes.join('\n* '))));
  }

  if (
  /* TODO: an org setting org.settings?.['maintains DRP/BCP'] || */
  drpBcpNotes.length > 0) {
    console.log('\n### DRP/BCP notes\n\n');
    console.log("".concat(drpBcpNotes.length === 0 ? '_none_' : "* ".concat(drpBcpNotes.join('\n* '))));
  }

  if (packageData !== null && packageData !== void 0 && (_packageData$liq2 = packageData.liq) !== null && _packageData$liq2 !== void 0 && (_packageData$liq2$con = _packageData$liq2.contracts) !== null && _packageData$liq2$con !== void 0 && _packageData$liq2$con['high availability'] || backoutNotes.length > 0) {
    console.log('\n### Backout notes\n\n');
    console.log("".concat(backoutNotes.length === 0 ? '_none_' : "* ".concat(backoutNotes.join('\n* '))));
  }
};

var arrayWithHoles = createCommonjsModule(function (module) {
function _arrayWithHoles(arr) {
  if (Array.isArray(arr)) return arr;
}

module.exports = _arrayWithHoles;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

unwrapExports(arrayWithHoles);

var iterableToArrayLimit = createCommonjsModule(function (module) {
function _iterableToArrayLimit(arr, i) {
  var _i = arr == null ? null : typeof Symbol !== "undefined" && arr[Symbol.iterator] || arr["@@iterator"];

  if (_i == null) return;
  var _arr = [];
  var _n = true;
  var _d = false;

  var _s, _e;

  try {
    for (_i = _i.call(arr); !(_n = (_s = _i.next()).done); _n = true) {
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

module.exports = _iterableToArrayLimit;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

unwrapExports(iterableToArrayLimit);

var arrayLikeToArray = createCommonjsModule(function (module) {
function _arrayLikeToArray(arr, len) {
  if (len == null || len > arr.length) len = arr.length;

  for (var i = 0, arr2 = new Array(len); i < len; i++) {
    arr2[i] = arr[i];
  }

  return arr2;
}

module.exports = _arrayLikeToArray;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

unwrapExports(arrayLikeToArray);

var unsupportedIterableToArray = createCommonjsModule(function (module) {
function _unsupportedIterableToArray(o, minLen) {
  if (!o) return;
  if (typeof o === "string") return arrayLikeToArray(o, minLen);
  var n = Object.prototype.toString.call(o).slice(8, -1);
  if (n === "Object" && o.constructor) n = o.constructor.name;
  if (n === "Map" || n === "Set") return Array.from(o);
  if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return arrayLikeToArray(o, minLen);
}

module.exports = _unsupportedIterableToArray;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

unwrapExports(unsupportedIterableToArray);

var nonIterableRest = createCommonjsModule(function (module) {
function _nonIterableRest() {
  throw new TypeError("Invalid attempt to destructure non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}

module.exports = _nonIterableRest;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

unwrapExports(nonIterableRest);

var slicedToArray = createCommonjsModule(function (module) {
function _slicedToArray(arr, i) {
  return arrayWithHoles(arr) || iterableToArrayLimit(arr, i) || unsupportedIterableToArray(arr, i) || nonIterableRest();
}

module.exports = _slicedToArray;
module.exports["default"] = module.exports, module.exports.__esModule = true;
});

var _slicedToArray = unwrapExports(slicedToArray);

function _createForOfIteratorHelper(o, allowArrayLike) { var it = typeof Symbol !== "undefined" && o[Symbol.iterator] || o["@@iterator"]; if (!it) { if (Array.isArray(o) || (it = _unsupportedIterableToArray(o)) || allowArrayLike && o && typeof o.length === "number") { if (it) o = it; var i = 0; var F = function F() {}; return { s: F, n: function n() { if (i >= o.length) return { done: true }; return { done: false, value: o[i++] }; }, e: function e(_e) { throw _e; }, f: F }; } throw new TypeError("Invalid attempt to iterate non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method."); } var normalCompletion = true, didErr = false, err; return { s: function s() { it = it.call(o); }, n: function n() { var step = it.next(); normalCompletion = step.done; return step; }, e: function e(_e2) { didErr = true; err = _e2; }, f: function f() { try { if (!normalCompletion && it["return"] != null) it["return"](); } finally { if (didErr) throw err; } } }; }

function _unsupportedIterableToArray(o, minLen) { if (!o) return; if (typeof o === "string") return _arrayLikeToArray(o, minLen); var n = Object.prototype.toString.call(o).slice(8, -1); if (n === "Object" && o.constructor) n = o.constructor.name; if (n === "Map" || n === "Set") return Array.from(o); if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen); }

function _arrayLikeToArray(arr, len) { if (len == null || len > arr.length) len = arr.length; for (var i = 0, arr2 = new Array(len); i < len; i++) { arr2[i] = arr[i]; } return arr2; }

var readOldChangelog = function readOldChangelog() {
  var clPath = requireEnv('CHANGELOG_FILE');
  var oldClPath = "".concat(clPath.substring(0, clPath.length - 5), ".json");
  var oldClContents = fs__namespace.readFileSync(oldClPath);
  var oldCl = JSON.parse(oldClContents);
  return oldCl;
};

var convertFormat = function convertFormat(changelog) {
  changelog.reverse(); // in-place modification

  var _iterator = _createForOfIteratorHelper(changelog),
      _step;

  try {
    for (_iterator.s(); !(_step = _iterator.n()).done;) {
      var entry = _step.value;
      var newStart = new Date();
      newStart.setTime(0); // old format: UTC:yyyy-mm-dd-HHMM Z

      var _entry$startTimestamp = entry.startTimestampLocal.split(' ')[0].split('-'),
          _entry$startTimestamp2 = _slicedToArray(_entry$startTimestamp, 4),
          year = _entry$startTimestamp2[0],
          month = _entry$startTimestamp2[1],
          date = _entry$startTimestamp2[2],
          time = _entry$startTimestamp2[3];

      var hour = time.substring(0, 2);
      var minutes = time.substring(2);
      newStart.setUTCFullYear(year);
      newStart.setUTCMonth(month - 1);
      newStart.setUTCDate(date);
      newStart.setUTCHours(hour);
      newStart.setUTCMinutes(minutes);
      entry.startTimestamp = newStart.toISOString();
      delete entry.startTimestampLocal;
      entry.startEpochMillis = newStart.getTime();
      entry.changeNotes = [entry.description];
      delete entry.description;
      entry.securityNotes = [];
      entry.drpBcpNotes = [];
      entry.backoutNotes = [];
    }
  } catch (err) {
    _iterator.e(err);
  } finally {
    _iterator.f();
  }

  return changelog;
};

var updateFileFormat = function updateFileFormat() {
  var oldCl = readOldChangelog();
  var changelog = convertFormat(oldCl);
  saveChangelog(changelog);
};

var ADD_ENTRY = 'add-entry';
var FINALIZE_ENTRY = 'finalize-entry';
var PRINT_ENTRIES = 'print-entries';
var UPDATE_FORMAT = 'update-format';
var validActions = [ADD_ENTRY, FINALIZE_ENTRY, PRINT_ENTRIES, UPDATE_FORMAT];

var determineAction = function determineAction() {
  var args = process.argv.slice(2);

  if (args.length === 0) {
    // || args.length > 1) { TODO: we do need args for 'print-changelog'...
    throw new Error('Unexpected argument count. Please provide exactly one action argument.');
  }

  var action = args[0];

  if (validActions.indexOf(action) === -1) {
    throw new Error("Invalid action: ".concat(action));
  }

  switch (action) {
    case ADD_ENTRY:
      return addEntry;

    case FINALIZE_ENTRY:
      return finalizeChangelog;

    case PRINT_ENTRIES:
      return function () {
        return printEntries(JSON.parse(args[1]), new Date(args[2]));
      };

    case UPDATE_FORMAT:
      return updateFileFormat;

    default:
      throw new Error("Cannot process unkown action: ".concat(action));
  }
};

var execute = function execute() {
  determineAction().call();
};

execute();
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFuYWdlLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvY2hhbmdlbG9nL2xpYi1jaGFuZ2Vsb2ctY29yZS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9hc3luY1RvR2VuZXJhdG9yLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3JlZ2VuZXJhdG9yLXJ1bnRpbWUvcnVudGltZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9yZWdlbmVyYXRvci9pbmRleC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1maW5hbGl6ZS1lbnRyeS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1wcmludC1lbnRyaWVzLmpzIiwiLi4vbm9kZV9tb2R1bGVzL0BiYWJlbC9ydW50aW1lL2hlbHBlcnMvYXJyYXlXaXRoSG9sZXMuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9pdGVyYWJsZVRvQXJyYXlMaW1pdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL2FycmF5TGlrZVRvQXJyYXkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL25vbkl0ZXJhYmxlUmVzdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL3NsaWNlZFRvQXJyYXkuanMiLCIuLi9zcmMvbGlxL2FjdGlvbnMvd29yay9jaGFuZ2Vsb2cvbGliLWNoYW5nZWxvZy1hY3Rpb24tdXBkYXRlLWZvcm1hdC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLXJ1bm5lci5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9pbmRleC5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcbmltcG9ydCBZQU1MIGZyb20gJ3lhbWwnXG5cbmNvbnN0IHJlYWRDaGFuZ2Vsb2cgPSAoKSA9PiB7XG4gIGNvbnN0IGNsUGF0aGlzaCA9IHJlcXVpcmVFbnYoJ0NIQU5HRUxPR19GSUxFJylcbiAgY29uc3QgY2xQYXRoID0gY2xQYXRoaXNoID09PSAnLScgPyAwIDogY2xQYXRoaXNoXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoY2xQYXRoLCAndXRmOCcpIC8vIGluY2x1ZGUgZW5jb2RpbmcgdG8gZ2V0ICdzdHJpbmcnIHJlc3VsdFxuICBjb25zdCBjaGFuZ2Vsb2cgPSBZQU1MLnBhcnNlKGNoYW5nZWxvZ0NvbnRlbnRzKVxuXG4gIHJldHVybiBjaGFuZ2Vsb2dcbn1cblxuY29uc3QgcmVxdWlyZUVudiA9IChrZXkpID0+IHtcbiAgcmV0dXJuIHByb2Nlc3MuZW52W2tleV0gfHwgdGhyb3cgbmV3IEVycm9yKGBEaWQgbm90IGZpbmQgcmVxdWlyZWQgZW52aXJvbm1lbnQgcGFyYW1ldGVyOiAke2tleX1gKVxufVxuXG5jb25zdCBzYXZlQ2hhbmdlbG9nID0gKGNoYW5nZWxvZykgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBZQU1MLnN0cmluZ2lmeShjaGFuZ2Vsb2cpXG4gIGZzLndyaXRlRmlsZVN5bmMoY2xQYXRoLCBjaGFuZ2Vsb2dDb250ZW50cylcbn1cblxuZXhwb3J0IHtcbiAgcmVhZENoYW5nZWxvZyxcbiAgcmVxdWlyZUVudixcbiAgc2F2ZUNoYW5nZWxvZ1xufVxuIiwiaW1wb3J0IGRhdGVGb3JtYXQgZnJvbSAnZGF0ZWZvcm1hdCdcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZywgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBjcmVhdGVOZXdFbnRyeSA9IChjaGFuZ2Vsb2cpID0+IHtcbiAgLy8gZ2V0IHRoZSBhcHByb3ggc3RhcnQgdGltZSBhY2NvcmRpbmcgdG8gdGhlIGxvY2FsIGNsb2NrXG4gIGNvbnN0IG5vdyA9IG5ldyBEYXRlKClcbiAgY29uc3Qgc3RhcnRUaW1lc3RhbXAgPSBkYXRlRm9ybWF0KG5vdywgJ1VUQzp5eXl5LW1tLWRkLUhITU0uc3MgWicpXG4gIGNvbnN0IHN0YXJ0RXBvY2hNaWxsaXMgPSBub3cubm93KClcbiAgLy8gcHJvY2VzcyB0aGUgJ3dvcmsgdW5pdCcgZGF0YVxuICBjb25zdCBpc3N1ZXMgPSByZXF1aXJlRW52KCdXT1JLX0lTU1VFUycpLnNwbGl0KCdcXG4nKVxuICBjb25zdCBpbnZvbHZlZFByb2plY3RzID0gcmVxdWlyZUVudignSU5WT0xWRURfUFJPSkVDVFMnKS5zcGxpdCgnXFxuJylcblxuICBjb25zdCBuZXdFbnRyeSA9IHtcbiAgICBzdGFydFRpbWVzdGFtcCxcbiAgICBzdGFydEVwb2NoTWlsbGlzLFxuICAgIGlzc3VlcyxcbiAgICBicmFuY2ggICAgICAgICAgOiByZXF1aXJlRW52KCdXT1JLX0JSQU5DSCcpLFxuICAgIGJyYW5jaEZyb20gICAgICA6IHJlcXVpcmVFbnYoJ0NVUlJfUkVQT19WRVJTSU9OJyksXG4gICAgd29ya0luaXRpYXRvciAgIDogcmVxdWlyZUVudignV09SS19JTklUSUFUT1InKSxcbiAgICBicmFuY2hJbml0aWF0b3IgOiByZXF1aXJlRW52KCdDVVJSX1VTRVInKSxcbiAgICBpbnZvbHZlZFByb2plY3RzLFxuICAgIGNoYW5nZU5vdGVzICAgICA6IFtyZXF1aXJlRW52KCdXT1JLX0RFU0MnKV0sXG4gICAgc2VjdXJpdHlOb3RlcyAgIDogW10sXG4gICAgZHJwQmNwTm90ZXMgICAgIDogW10sXG4gICAgYmFja291dE5vdGVzICAgIDogW11cbiAgfVxuXG4gIGNoYW5nZWxvZy5wdXNoKG5ld0VudHJ5KVxuICByZXR1cm4gbmV3RW50cnlcbn1cblxuY29uc3QgYWRkRW50cnkgPSAoKSA9PiB7XG4gIGNvbnN0IGNoYW5nZWxvZyA9IHJlYWRDaGFuZ2Vsb2coKVxuICBjcmVhdGVOZXdFbnRyeShjaGFuZ2Vsb2cpXG4gIHNhdmVDaGFuZ2Vsb2coY2hhbmdlbG9nKVxufVxuXG5leHBvcnQgeyBhZGRFbnRyeSwgY3JlYXRlTmV3RW50cnkgfVxuIiwiZnVuY3Rpb24gYXN5bmNHZW5lcmF0b3JTdGVwKGdlbiwgcmVzb2x2ZSwgcmVqZWN0LCBfbmV4dCwgX3Rocm93LCBrZXksIGFyZykge1xuICB0cnkge1xuICAgIHZhciBpbmZvID0gZ2VuW2tleV0oYXJnKTtcbiAgICB2YXIgdmFsdWUgPSBpbmZvLnZhbHVlO1xuICB9IGNhdGNoIChlcnJvcikge1xuICAgIHJlamVjdChlcnJvcik7XG4gICAgcmV0dXJuO1xuICB9XG5cbiAgaWYgKGluZm8uZG9uZSkge1xuICAgIHJlc29sdmUodmFsdWUpO1xuICB9IGVsc2Uge1xuICAgIFByb21pc2UucmVzb2x2ZSh2YWx1ZSkudGhlbihfbmV4dCwgX3Rocm93KTtcbiAgfVxufVxuXG5mdW5jdGlvbiBfYXN5bmNUb0dlbmVyYXRvcihmbikge1xuICByZXR1cm4gZnVuY3Rpb24gKCkge1xuICAgIHZhciBzZWxmID0gdGhpcyxcbiAgICAgICAgYXJncyA9IGFyZ3VtZW50cztcbiAgICByZXR1cm4gbmV3IFByb21pc2UoZnVuY3Rpb24gKHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgdmFyIGdlbiA9IGZuLmFwcGx5KHNlbGYsIGFyZ3MpO1xuXG4gICAgICBmdW5jdGlvbiBfbmV4dCh2YWx1ZSkge1xuICAgICAgICBhc3luY0dlbmVyYXRvclN0ZXAoZ2VuLCByZXNvbHZlLCByZWplY3QsIF9uZXh0LCBfdGhyb3csIFwibmV4dFwiLCB2YWx1ZSk7XG4gICAgICB9XG5cbiAgICAgIGZ1bmN0aW9uIF90aHJvdyhlcnIpIHtcbiAgICAgICAgYXN5bmNHZW5lcmF0b3JTdGVwKGdlbiwgcmVzb2x2ZSwgcmVqZWN0LCBfbmV4dCwgX3Rocm93LCBcInRocm93XCIsIGVycik7XG4gICAgICB9XG5cbiAgICAgIF9uZXh0KHVuZGVmaW5lZCk7XG4gICAgfSk7XG4gIH07XG59XG5cbm1vZHVsZS5leHBvcnRzID0gX2FzeW5jVG9HZW5lcmF0b3I7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiLyoqXG4gKiBDb3B5cmlnaHQgKGMpIDIwMTQtcHJlc2VudCwgRmFjZWJvb2ssIEluYy5cbiAqXG4gKiBUaGlzIHNvdXJjZSBjb2RlIGlzIGxpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgbGljZW5zZSBmb3VuZCBpbiB0aGVcbiAqIExJQ0VOU0UgZmlsZSBpbiB0aGUgcm9vdCBkaXJlY3Rvcnkgb2YgdGhpcyBzb3VyY2UgdHJlZS5cbiAqL1xuXG52YXIgcnVudGltZSA9IChmdW5jdGlvbiAoZXhwb3J0cykge1xuICBcInVzZSBzdHJpY3RcIjtcblxuICB2YXIgT3AgPSBPYmplY3QucHJvdG90eXBlO1xuICB2YXIgaGFzT3duID0gT3AuaGFzT3duUHJvcGVydHk7XG4gIHZhciB1bmRlZmluZWQ7IC8vIE1vcmUgY29tcHJlc3NpYmxlIHRoYW4gdm9pZCAwLlxuICB2YXIgJFN5bWJvbCA9IHR5cGVvZiBTeW1ib2wgPT09IFwiZnVuY3Rpb25cIiA/IFN5bWJvbCA6IHt9O1xuICB2YXIgaXRlcmF0b3JTeW1ib2wgPSAkU3ltYm9sLml0ZXJhdG9yIHx8IFwiQEBpdGVyYXRvclwiO1xuICB2YXIgYXN5bmNJdGVyYXRvclN5bWJvbCA9ICRTeW1ib2wuYXN5bmNJdGVyYXRvciB8fCBcIkBAYXN5bmNJdGVyYXRvclwiO1xuICB2YXIgdG9TdHJpbmdUYWdTeW1ib2wgPSAkU3ltYm9sLnRvU3RyaW5nVGFnIHx8IFwiQEB0b1N0cmluZ1RhZ1wiO1xuXG4gIGZ1bmN0aW9uIGRlZmluZShvYmosIGtleSwgdmFsdWUpIHtcbiAgICBPYmplY3QuZGVmaW5lUHJvcGVydHkob2JqLCBrZXksIHtcbiAgICAgIHZhbHVlOiB2YWx1ZSxcbiAgICAgIGVudW1lcmFibGU6IHRydWUsXG4gICAgICBjb25maWd1cmFibGU6IHRydWUsXG4gICAgICB3cml0YWJsZTogdHJ1ZVxuICAgIH0pO1xuICAgIHJldHVybiBvYmpba2V5XTtcbiAgfVxuICB0cnkge1xuICAgIC8vIElFIDggaGFzIGEgYnJva2VuIE9iamVjdC5kZWZpbmVQcm9wZXJ0eSB0aGF0IG9ubHkgd29ya3Mgb24gRE9NIG9iamVjdHMuXG4gICAgZGVmaW5lKHt9LCBcIlwiKTtcbiAgfSBjYXRjaCAoZXJyKSB7XG4gICAgZGVmaW5lID0gZnVuY3Rpb24ob2JqLCBrZXksIHZhbHVlKSB7XG4gICAgICByZXR1cm4gb2JqW2tleV0gPSB2YWx1ZTtcbiAgICB9O1xuICB9XG5cbiAgZnVuY3Rpb24gd3JhcChpbm5lckZuLCBvdXRlckZuLCBzZWxmLCB0cnlMb2NzTGlzdCkge1xuICAgIC8vIElmIG91dGVyRm4gcHJvdmlkZWQgYW5kIG91dGVyRm4ucHJvdG90eXBlIGlzIGEgR2VuZXJhdG9yLCB0aGVuIG91dGVyRm4ucHJvdG90eXBlIGluc3RhbmNlb2YgR2VuZXJhdG9yLlxuICAgIHZhciBwcm90b0dlbmVyYXRvciA9IG91dGVyRm4gJiYgb3V0ZXJGbi5wcm90b3R5cGUgaW5zdGFuY2VvZiBHZW5lcmF0b3IgPyBvdXRlckZuIDogR2VuZXJhdG9yO1xuICAgIHZhciBnZW5lcmF0b3IgPSBPYmplY3QuY3JlYXRlKHByb3RvR2VuZXJhdG9yLnByb3RvdHlwZSk7XG4gICAgdmFyIGNvbnRleHQgPSBuZXcgQ29udGV4dCh0cnlMb2NzTGlzdCB8fCBbXSk7XG5cbiAgICAvLyBUaGUgLl9pbnZva2UgbWV0aG9kIHVuaWZpZXMgdGhlIGltcGxlbWVudGF0aW9ucyBvZiB0aGUgLm5leHQsXG4gICAgLy8gLnRocm93LCBhbmQgLnJldHVybiBtZXRob2RzLlxuICAgIGdlbmVyYXRvci5faW52b2tlID0gbWFrZUludm9rZU1ldGhvZChpbm5lckZuLCBzZWxmLCBjb250ZXh0KTtcblxuICAgIHJldHVybiBnZW5lcmF0b3I7XG4gIH1cbiAgZXhwb3J0cy53cmFwID0gd3JhcDtcblxuICAvLyBUcnkvY2F0Y2ggaGVscGVyIHRvIG1pbmltaXplIGRlb3B0aW1pemF0aW9ucy4gUmV0dXJucyBhIGNvbXBsZXRpb25cbiAgLy8gcmVjb3JkIGxpa2UgY29udGV4dC50cnlFbnRyaWVzW2ldLmNvbXBsZXRpb24uIFRoaXMgaW50ZXJmYWNlIGNvdWxkXG4gIC8vIGhhdmUgYmVlbiAoYW5kIHdhcyBwcmV2aW91c2x5KSBkZXNpZ25lZCB0byB0YWtlIGEgY2xvc3VyZSB0byBiZVxuICAvLyBpbnZva2VkIHdpdGhvdXQgYXJndW1lbnRzLCBidXQgaW4gYWxsIHRoZSBjYXNlcyB3ZSBjYXJlIGFib3V0IHdlXG4gIC8vIGFscmVhZHkgaGF2ZSBhbiBleGlzdGluZyBtZXRob2Qgd2Ugd2FudCB0byBjYWxsLCBzbyB0aGVyZSdzIG5vIG5lZWRcbiAgLy8gdG8gY3JlYXRlIGEgbmV3IGZ1bmN0aW9uIG9iamVjdC4gV2UgY2FuIGV2ZW4gZ2V0IGF3YXkgd2l0aCBhc3N1bWluZ1xuICAvLyB0aGUgbWV0aG9kIHRha2VzIGV4YWN0bHkgb25lIGFyZ3VtZW50LCBzaW5jZSB0aGF0IGhhcHBlbnMgdG8gYmUgdHJ1ZVxuICAvLyBpbiBldmVyeSBjYXNlLCBzbyB3ZSBkb24ndCBoYXZlIHRvIHRvdWNoIHRoZSBhcmd1bWVudHMgb2JqZWN0LiBUaGVcbiAgLy8gb25seSBhZGRpdGlvbmFsIGFsbG9jYXRpb24gcmVxdWlyZWQgaXMgdGhlIGNvbXBsZXRpb24gcmVjb3JkLCB3aGljaFxuICAvLyBoYXMgYSBzdGFibGUgc2hhcGUgYW5kIHNvIGhvcGVmdWxseSBzaG91bGQgYmUgY2hlYXAgdG8gYWxsb2NhdGUuXG4gIGZ1bmN0aW9uIHRyeUNhdGNoKGZuLCBvYmosIGFyZykge1xuICAgIHRyeSB7XG4gICAgICByZXR1cm4geyB0eXBlOiBcIm5vcm1hbFwiLCBhcmc6IGZuLmNhbGwob2JqLCBhcmcpIH07XG4gICAgfSBjYXRjaCAoZXJyKSB7XG4gICAgICByZXR1cm4geyB0eXBlOiBcInRocm93XCIsIGFyZzogZXJyIH07XG4gICAgfVxuICB9XG5cbiAgdmFyIEdlblN0YXRlU3VzcGVuZGVkU3RhcnQgPSBcInN1c3BlbmRlZFN0YXJ0XCI7XG4gIHZhciBHZW5TdGF0ZVN1c3BlbmRlZFlpZWxkID0gXCJzdXNwZW5kZWRZaWVsZFwiO1xuICB2YXIgR2VuU3RhdGVFeGVjdXRpbmcgPSBcImV4ZWN1dGluZ1wiO1xuICB2YXIgR2VuU3RhdGVDb21wbGV0ZWQgPSBcImNvbXBsZXRlZFwiO1xuXG4gIC8vIFJldHVybmluZyB0aGlzIG9iamVjdCBmcm9tIHRoZSBpbm5lckZuIGhhcyB0aGUgc2FtZSBlZmZlY3QgYXNcbiAgLy8gYnJlYWtpbmcgb3V0IG9mIHRoZSBkaXNwYXRjaCBzd2l0Y2ggc3RhdGVtZW50LlxuICB2YXIgQ29udGludWVTZW50aW5lbCA9IHt9O1xuXG4gIC8vIER1bW15IGNvbnN0cnVjdG9yIGZ1bmN0aW9ucyB0aGF0IHdlIHVzZSBhcyB0aGUgLmNvbnN0cnVjdG9yIGFuZFxuICAvLyAuY29uc3RydWN0b3IucHJvdG90eXBlIHByb3BlcnRpZXMgZm9yIGZ1bmN0aW9ucyB0aGF0IHJldHVybiBHZW5lcmF0b3JcbiAgLy8gb2JqZWN0cy4gRm9yIGZ1bGwgc3BlYyBjb21wbGlhbmNlLCB5b3UgbWF5IHdpc2ggdG8gY29uZmlndXJlIHlvdXJcbiAgLy8gbWluaWZpZXIgbm90IHRvIG1hbmdsZSB0aGUgbmFtZXMgb2YgdGhlc2UgdHdvIGZ1bmN0aW9ucy5cbiAgZnVuY3Rpb24gR2VuZXJhdG9yKCkge31cbiAgZnVuY3Rpb24gR2VuZXJhdG9yRnVuY3Rpb24oKSB7fVxuICBmdW5jdGlvbiBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZSgpIHt9XG5cbiAgLy8gVGhpcyBpcyBhIHBvbHlmaWxsIGZvciAlSXRlcmF0b3JQcm90b3R5cGUlIGZvciBlbnZpcm9ubWVudHMgdGhhdFxuICAvLyBkb24ndCBuYXRpdmVseSBzdXBwb3J0IGl0LlxuICB2YXIgSXRlcmF0b3JQcm90b3R5cGUgPSB7fTtcbiAgSXRlcmF0b3JQcm90b3R5cGVbaXRlcmF0b3JTeW1ib2xdID0gZnVuY3Rpb24gKCkge1xuICAgIHJldHVybiB0aGlzO1xuICB9O1xuXG4gIHZhciBnZXRQcm90byA9IE9iamVjdC5nZXRQcm90b3R5cGVPZjtcbiAgdmFyIE5hdGl2ZUl0ZXJhdG9yUHJvdG90eXBlID0gZ2V0UHJvdG8gJiYgZ2V0UHJvdG8oZ2V0UHJvdG8odmFsdWVzKFtdKSkpO1xuICBpZiAoTmF0aXZlSXRlcmF0b3JQcm90b3R5cGUgJiZcbiAgICAgIE5hdGl2ZUl0ZXJhdG9yUHJvdG90eXBlICE9PSBPcCAmJlxuICAgICAgaGFzT3duLmNhbGwoTmF0aXZlSXRlcmF0b3JQcm90b3R5cGUsIGl0ZXJhdG9yU3ltYm9sKSkge1xuICAgIC8vIFRoaXMgZW52aXJvbm1lbnQgaGFzIGEgbmF0aXZlICVJdGVyYXRvclByb3RvdHlwZSU7IHVzZSBpdCBpbnN0ZWFkXG4gICAgLy8gb2YgdGhlIHBvbHlmaWxsLlxuICAgIEl0ZXJhdG9yUHJvdG90eXBlID0gTmF0aXZlSXRlcmF0b3JQcm90b3R5cGU7XG4gIH1cblxuICB2YXIgR3AgPSBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZS5wcm90b3R5cGUgPVxuICAgIEdlbmVyYXRvci5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKEl0ZXJhdG9yUHJvdG90eXBlKTtcbiAgR2VuZXJhdG9yRnVuY3Rpb24ucHJvdG90eXBlID0gR3AuY29uc3RydWN0b3IgPSBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZTtcbiAgR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGUuY29uc3RydWN0b3IgPSBHZW5lcmF0b3JGdW5jdGlvbjtcbiAgR2VuZXJhdG9yRnVuY3Rpb24uZGlzcGxheU5hbWUgPSBkZWZpbmUoXG4gICAgR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGUsXG4gICAgdG9TdHJpbmdUYWdTeW1ib2wsXG4gICAgXCJHZW5lcmF0b3JGdW5jdGlvblwiXG4gICk7XG5cbiAgLy8gSGVscGVyIGZvciBkZWZpbmluZyB0aGUgLm5leHQsIC50aHJvdywgYW5kIC5yZXR1cm4gbWV0aG9kcyBvZiB0aGVcbiAgLy8gSXRlcmF0b3IgaW50ZXJmYWNlIGluIHRlcm1zIG9mIGEgc2luZ2xlIC5faW52b2tlIG1ldGhvZC5cbiAgZnVuY3Rpb24gZGVmaW5lSXRlcmF0b3JNZXRob2RzKHByb3RvdHlwZSkge1xuICAgIFtcIm5leHRcIiwgXCJ0aHJvd1wiLCBcInJldHVyblwiXS5mb3JFYWNoKGZ1bmN0aW9uKG1ldGhvZCkge1xuICAgICAgZGVmaW5lKHByb3RvdHlwZSwgbWV0aG9kLCBmdW5jdGlvbihhcmcpIHtcbiAgICAgICAgcmV0dXJuIHRoaXMuX2ludm9rZShtZXRob2QsIGFyZyk7XG4gICAgICB9KTtcbiAgICB9KTtcbiAgfVxuXG4gIGV4cG9ydHMuaXNHZW5lcmF0b3JGdW5jdGlvbiA9IGZ1bmN0aW9uKGdlbkZ1bikge1xuICAgIHZhciBjdG9yID0gdHlwZW9mIGdlbkZ1biA9PT0gXCJmdW5jdGlvblwiICYmIGdlbkZ1bi5jb25zdHJ1Y3RvcjtcbiAgICByZXR1cm4gY3RvclxuICAgICAgPyBjdG9yID09PSBHZW5lcmF0b3JGdW5jdGlvbiB8fFxuICAgICAgICAvLyBGb3IgdGhlIG5hdGl2ZSBHZW5lcmF0b3JGdW5jdGlvbiBjb25zdHJ1Y3RvciwgdGhlIGJlc3Qgd2UgY2FuXG4gICAgICAgIC8vIGRvIGlzIHRvIGNoZWNrIGl0cyAubmFtZSBwcm9wZXJ0eS5cbiAgICAgICAgKGN0b3IuZGlzcGxheU5hbWUgfHwgY3Rvci5uYW1lKSA9PT0gXCJHZW5lcmF0b3JGdW5jdGlvblwiXG4gICAgICA6IGZhbHNlO1xuICB9O1xuXG4gIGV4cG9ydHMubWFyayA9IGZ1bmN0aW9uKGdlbkZ1bikge1xuICAgIGlmIChPYmplY3Quc2V0UHJvdG90eXBlT2YpIHtcbiAgICAgIE9iamVjdC5zZXRQcm90b3R5cGVPZihnZW5GdW4sIEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlKTtcbiAgICB9IGVsc2Uge1xuICAgICAgZ2VuRnVuLl9fcHJvdG9fXyA9IEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlO1xuICAgICAgZGVmaW5lKGdlbkZ1biwgdG9TdHJpbmdUYWdTeW1ib2wsIFwiR2VuZXJhdG9yRnVuY3Rpb25cIik7XG4gICAgfVxuICAgIGdlbkZ1bi5wcm90b3R5cGUgPSBPYmplY3QuY3JlYXRlKEdwKTtcbiAgICByZXR1cm4gZ2VuRnVuO1xuICB9O1xuXG4gIC8vIFdpdGhpbiB0aGUgYm9keSBvZiBhbnkgYXN5bmMgZnVuY3Rpb24sIGBhd2FpdCB4YCBpcyB0cmFuc2Zvcm1lZCB0b1xuICAvLyBgeWllbGQgcmVnZW5lcmF0b3JSdW50aW1lLmF3cmFwKHgpYCwgc28gdGhhdCB0aGUgcnVudGltZSBjYW4gdGVzdFxuICAvLyBgaGFzT3duLmNhbGwodmFsdWUsIFwiX19hd2FpdFwiKWAgdG8gZGV0ZXJtaW5lIGlmIHRoZSB5aWVsZGVkIHZhbHVlIGlzXG4gIC8vIG1lYW50IHRvIGJlIGF3YWl0ZWQuXG4gIGV4cG9ydHMuYXdyYXAgPSBmdW5jdGlvbihhcmcpIHtcbiAgICByZXR1cm4geyBfX2F3YWl0OiBhcmcgfTtcbiAgfTtcblxuICBmdW5jdGlvbiBBc3luY0l0ZXJhdG9yKGdlbmVyYXRvciwgUHJvbWlzZUltcGwpIHtcbiAgICBmdW5jdGlvbiBpbnZva2UobWV0aG9kLCBhcmcsIHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgdmFyIHJlY29yZCA9IHRyeUNhdGNoKGdlbmVyYXRvclttZXRob2RdLCBnZW5lcmF0b3IsIGFyZyk7XG4gICAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgICByZWplY3QocmVjb3JkLmFyZyk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB2YXIgcmVzdWx0ID0gcmVjb3JkLmFyZztcbiAgICAgICAgdmFyIHZhbHVlID0gcmVzdWx0LnZhbHVlO1xuICAgICAgICBpZiAodmFsdWUgJiZcbiAgICAgICAgICAgIHR5cGVvZiB2YWx1ZSA9PT0gXCJvYmplY3RcIiAmJlxuICAgICAgICAgICAgaGFzT3duLmNhbGwodmFsdWUsIFwiX19hd2FpdFwiKSkge1xuICAgICAgICAgIHJldHVybiBQcm9taXNlSW1wbC5yZXNvbHZlKHZhbHVlLl9fYXdhaXQpLnRoZW4oZnVuY3Rpb24odmFsdWUpIHtcbiAgICAgICAgICAgIGludm9rZShcIm5leHRcIiwgdmFsdWUsIHJlc29sdmUsIHJlamVjdCk7XG4gICAgICAgICAgfSwgZnVuY3Rpb24oZXJyKSB7XG4gICAgICAgICAgICBpbnZva2UoXCJ0aHJvd1wiLCBlcnIsIHJlc29sdmUsIHJlamVjdCk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cblxuICAgICAgICByZXR1cm4gUHJvbWlzZUltcGwucmVzb2x2ZSh2YWx1ZSkudGhlbihmdW5jdGlvbih1bndyYXBwZWQpIHtcbiAgICAgICAgICAvLyBXaGVuIGEgeWllbGRlZCBQcm9taXNlIGlzIHJlc29sdmVkLCBpdHMgZmluYWwgdmFsdWUgYmVjb21lc1xuICAgICAgICAgIC8vIHRoZSAudmFsdWUgb2YgdGhlIFByb21pc2U8e3ZhbHVlLGRvbmV9PiByZXN1bHQgZm9yIHRoZVxuICAgICAgICAgIC8vIGN1cnJlbnQgaXRlcmF0aW9uLlxuICAgICAgICAgIHJlc3VsdC52YWx1ZSA9IHVud3JhcHBlZDtcbiAgICAgICAgICByZXNvbHZlKHJlc3VsdCk7XG4gICAgICAgIH0sIGZ1bmN0aW9uKGVycm9yKSB7XG4gICAgICAgICAgLy8gSWYgYSByZWplY3RlZCBQcm9taXNlIHdhcyB5aWVsZGVkLCB0aHJvdyB0aGUgcmVqZWN0aW9uIGJhY2tcbiAgICAgICAgICAvLyBpbnRvIHRoZSBhc3luYyBnZW5lcmF0b3IgZnVuY3Rpb24gc28gaXQgY2FuIGJlIGhhbmRsZWQgdGhlcmUuXG4gICAgICAgICAgcmV0dXJuIGludm9rZShcInRocm93XCIsIGVycm9yLCByZXNvbHZlLCByZWplY3QpO1xuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICB2YXIgcHJldmlvdXNQcm9taXNlO1xuXG4gICAgZnVuY3Rpb24gZW5xdWV1ZShtZXRob2QsIGFyZykge1xuICAgICAgZnVuY3Rpb24gY2FsbEludm9rZVdpdGhNZXRob2RBbmRBcmcoKSB7XG4gICAgICAgIHJldHVybiBuZXcgUHJvbWlzZUltcGwoZnVuY3Rpb24ocmVzb2x2ZSwgcmVqZWN0KSB7XG4gICAgICAgICAgaW52b2tlKG1ldGhvZCwgYXJnLCByZXNvbHZlLCByZWplY3QpO1xuICAgICAgICB9KTtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHByZXZpb3VzUHJvbWlzZSA9XG4gICAgICAgIC8vIElmIGVucXVldWUgaGFzIGJlZW4gY2FsbGVkIGJlZm9yZSwgdGhlbiB3ZSB3YW50IHRvIHdhaXQgdW50aWxcbiAgICAgICAgLy8gYWxsIHByZXZpb3VzIFByb21pc2VzIGhhdmUgYmVlbiByZXNvbHZlZCBiZWZvcmUgY2FsbGluZyBpbnZva2UsXG4gICAgICAgIC8vIHNvIHRoYXQgcmVzdWx0cyBhcmUgYWx3YXlzIGRlbGl2ZXJlZCBpbiB0aGUgY29ycmVjdCBvcmRlci4gSWZcbiAgICAgICAgLy8gZW5xdWV1ZSBoYXMgbm90IGJlZW4gY2FsbGVkIGJlZm9yZSwgdGhlbiBpdCBpcyBpbXBvcnRhbnQgdG9cbiAgICAgICAgLy8gY2FsbCBpbnZva2UgaW1tZWRpYXRlbHksIHdpdGhvdXQgd2FpdGluZyBvbiBhIGNhbGxiYWNrIHRvIGZpcmUsXG4gICAgICAgIC8vIHNvIHRoYXQgdGhlIGFzeW5jIGdlbmVyYXRvciBmdW5jdGlvbiBoYXMgdGhlIG9wcG9ydHVuaXR5IHRvIGRvXG4gICAgICAgIC8vIGFueSBuZWNlc3Nhcnkgc2V0dXAgaW4gYSBwcmVkaWN0YWJsZSB3YXkuIFRoaXMgcHJlZGljdGFiaWxpdHlcbiAgICAgICAgLy8gaXMgd2h5IHRoZSBQcm9taXNlIGNvbnN0cnVjdG9yIHN5bmNocm9ub3VzbHkgaW52b2tlcyBpdHNcbiAgICAgICAgLy8gZXhlY3V0b3IgY2FsbGJhY2ssIGFuZCB3aHkgYXN5bmMgZnVuY3Rpb25zIHN5bmNocm9ub3VzbHlcbiAgICAgICAgLy8gZXhlY3V0ZSBjb2RlIGJlZm9yZSB0aGUgZmlyc3QgYXdhaXQuIFNpbmNlIHdlIGltcGxlbWVudCBzaW1wbGVcbiAgICAgICAgLy8gYXN5bmMgZnVuY3Rpb25zIGluIHRlcm1zIG9mIGFzeW5jIGdlbmVyYXRvcnMsIGl0IGlzIGVzcGVjaWFsbHlcbiAgICAgICAgLy8gaW1wb3J0YW50IHRvIGdldCB0aGlzIHJpZ2h0LCBldmVuIHRob3VnaCBpdCByZXF1aXJlcyBjYXJlLlxuICAgICAgICBwcmV2aW91c1Byb21pc2UgPyBwcmV2aW91c1Byb21pc2UudGhlbihcbiAgICAgICAgICBjYWxsSW52b2tlV2l0aE1ldGhvZEFuZEFyZyxcbiAgICAgICAgICAvLyBBdm9pZCBwcm9wYWdhdGluZyBmYWlsdXJlcyB0byBQcm9taXNlcyByZXR1cm5lZCBieSBsYXRlclxuICAgICAgICAgIC8vIGludm9jYXRpb25zIG9mIHRoZSBpdGVyYXRvci5cbiAgICAgICAgICBjYWxsSW52b2tlV2l0aE1ldGhvZEFuZEFyZ1xuICAgICAgICApIDogY2FsbEludm9rZVdpdGhNZXRob2RBbmRBcmcoKTtcbiAgICB9XG5cbiAgICAvLyBEZWZpbmUgdGhlIHVuaWZpZWQgaGVscGVyIG1ldGhvZCB0aGF0IGlzIHVzZWQgdG8gaW1wbGVtZW50IC5uZXh0LFxuICAgIC8vIC50aHJvdywgYW5kIC5yZXR1cm4gKHNlZSBkZWZpbmVJdGVyYXRvck1ldGhvZHMpLlxuICAgIHRoaXMuX2ludm9rZSA9IGVucXVldWU7XG4gIH1cblxuICBkZWZpbmVJdGVyYXRvck1ldGhvZHMoQXN5bmNJdGVyYXRvci5wcm90b3R5cGUpO1xuICBBc3luY0l0ZXJhdG9yLnByb3RvdHlwZVthc3luY0l0ZXJhdG9yU3ltYm9sXSA9IGZ1bmN0aW9uICgpIHtcbiAgICByZXR1cm4gdGhpcztcbiAgfTtcbiAgZXhwb3J0cy5Bc3luY0l0ZXJhdG9yID0gQXN5bmNJdGVyYXRvcjtcblxuICAvLyBOb3RlIHRoYXQgc2ltcGxlIGFzeW5jIGZ1bmN0aW9ucyBhcmUgaW1wbGVtZW50ZWQgb24gdG9wIG9mXG4gIC8vIEFzeW5jSXRlcmF0b3Igb2JqZWN0czsgdGhleSBqdXN0IHJldHVybiBhIFByb21pc2UgZm9yIHRoZSB2YWx1ZSBvZlxuICAvLyB0aGUgZmluYWwgcmVzdWx0IHByb2R1Y2VkIGJ5IHRoZSBpdGVyYXRvci5cbiAgZXhwb3J0cy5hc3luYyA9IGZ1bmN0aW9uKGlubmVyRm4sIG91dGVyRm4sIHNlbGYsIHRyeUxvY3NMaXN0LCBQcm9taXNlSW1wbCkge1xuICAgIGlmIChQcm9taXNlSW1wbCA9PT0gdm9pZCAwKSBQcm9taXNlSW1wbCA9IFByb21pc2U7XG5cbiAgICB2YXIgaXRlciA9IG5ldyBBc3luY0l0ZXJhdG9yKFxuICAgICAgd3JhcChpbm5lckZuLCBvdXRlckZuLCBzZWxmLCB0cnlMb2NzTGlzdCksXG4gICAgICBQcm9taXNlSW1wbFxuICAgICk7XG5cbiAgICByZXR1cm4gZXhwb3J0cy5pc0dlbmVyYXRvckZ1bmN0aW9uKG91dGVyRm4pXG4gICAgICA/IGl0ZXIgLy8gSWYgb3V0ZXJGbiBpcyBhIGdlbmVyYXRvciwgcmV0dXJuIHRoZSBmdWxsIGl0ZXJhdG9yLlxuICAgICAgOiBpdGVyLm5leHQoKS50aGVuKGZ1bmN0aW9uKHJlc3VsdCkge1xuICAgICAgICAgIHJldHVybiByZXN1bHQuZG9uZSA/IHJlc3VsdC52YWx1ZSA6IGl0ZXIubmV4dCgpO1xuICAgICAgICB9KTtcbiAgfTtcblxuICBmdW5jdGlvbiBtYWtlSW52b2tlTWV0aG9kKGlubmVyRm4sIHNlbGYsIGNvbnRleHQpIHtcbiAgICB2YXIgc3RhdGUgPSBHZW5TdGF0ZVN1c3BlbmRlZFN0YXJ0O1xuXG4gICAgcmV0dXJuIGZ1bmN0aW9uIGludm9rZShtZXRob2QsIGFyZykge1xuICAgICAgaWYgKHN0YXRlID09PSBHZW5TdGF0ZUV4ZWN1dGluZykge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXCJHZW5lcmF0b3IgaXMgYWxyZWFkeSBydW5uaW5nXCIpO1xuICAgICAgfVxuXG4gICAgICBpZiAoc3RhdGUgPT09IEdlblN0YXRlQ29tcGxldGVkKSB7XG4gICAgICAgIGlmIChtZXRob2QgPT09IFwidGhyb3dcIikge1xuICAgICAgICAgIHRocm93IGFyZztcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIEJlIGZvcmdpdmluZywgcGVyIDI1LjMuMy4zLjMgb2YgdGhlIHNwZWM6XG4gICAgICAgIC8vIGh0dHBzOi8vcGVvcGxlLm1vemlsbGEub3JnL35qb3JlbmRvcmZmL2VzNi1kcmFmdC5odG1sI3NlYy1nZW5lcmF0b3JyZXN1bWVcbiAgICAgICAgcmV0dXJuIGRvbmVSZXN1bHQoKTtcbiAgICAgIH1cblxuICAgICAgY29udGV4dC5tZXRob2QgPSBtZXRob2Q7XG4gICAgICBjb250ZXh0LmFyZyA9IGFyZztcblxuICAgICAgd2hpbGUgKHRydWUpIHtcbiAgICAgICAgdmFyIGRlbGVnYXRlID0gY29udGV4dC5kZWxlZ2F0ZTtcbiAgICAgICAgaWYgKGRlbGVnYXRlKSB7XG4gICAgICAgICAgdmFyIGRlbGVnYXRlUmVzdWx0ID0gbWF5YmVJbnZva2VEZWxlZ2F0ZShkZWxlZ2F0ZSwgY29udGV4dCk7XG4gICAgICAgICAgaWYgKGRlbGVnYXRlUmVzdWx0KSB7XG4gICAgICAgICAgICBpZiAoZGVsZWdhdGVSZXN1bHQgPT09IENvbnRpbnVlU2VudGluZWwpIGNvbnRpbnVlO1xuICAgICAgICAgICAgcmV0dXJuIGRlbGVnYXRlUmVzdWx0O1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChjb250ZXh0Lm1ldGhvZCA9PT0gXCJuZXh0XCIpIHtcbiAgICAgICAgICAvLyBTZXR0aW5nIGNvbnRleHQuX3NlbnQgZm9yIGxlZ2FjeSBzdXBwb3J0IG9mIEJhYmVsJ3NcbiAgICAgICAgICAvLyBmdW5jdGlvbi5zZW50IGltcGxlbWVudGF0aW9uLlxuICAgICAgICAgIGNvbnRleHQuc2VudCA9IGNvbnRleHQuX3NlbnQgPSBjb250ZXh0LmFyZztcblxuICAgICAgICB9IGVsc2UgaWYgKGNvbnRleHQubWV0aG9kID09PSBcInRocm93XCIpIHtcbiAgICAgICAgICBpZiAoc3RhdGUgPT09IEdlblN0YXRlU3VzcGVuZGVkU3RhcnQpIHtcbiAgICAgICAgICAgIHN0YXRlID0gR2VuU3RhdGVDb21wbGV0ZWQ7XG4gICAgICAgICAgICB0aHJvdyBjb250ZXh0LmFyZztcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjb250ZXh0LmRpc3BhdGNoRXhjZXB0aW9uKGNvbnRleHQuYXJnKTtcblxuICAgICAgICB9IGVsc2UgaWYgKGNvbnRleHQubWV0aG9kID09PSBcInJldHVyblwiKSB7XG4gICAgICAgICAgY29udGV4dC5hYnJ1cHQoXCJyZXR1cm5cIiwgY29udGV4dC5hcmcpO1xuICAgICAgICB9XG5cbiAgICAgICAgc3RhdGUgPSBHZW5TdGF0ZUV4ZWN1dGluZztcblxuICAgICAgICB2YXIgcmVjb3JkID0gdHJ5Q2F0Y2goaW5uZXJGbiwgc2VsZiwgY29udGV4dCk7XG4gICAgICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJub3JtYWxcIikge1xuICAgICAgICAgIC8vIElmIGFuIGV4Y2VwdGlvbiBpcyB0aHJvd24gZnJvbSBpbm5lckZuLCB3ZSBsZWF2ZSBzdGF0ZSA9PT1cbiAgICAgICAgICAvLyBHZW5TdGF0ZUV4ZWN1dGluZyBhbmQgbG9vcCBiYWNrIGZvciBhbm90aGVyIGludm9jYXRpb24uXG4gICAgICAgICAgc3RhdGUgPSBjb250ZXh0LmRvbmVcbiAgICAgICAgICAgID8gR2VuU3RhdGVDb21wbGV0ZWRcbiAgICAgICAgICAgIDogR2VuU3RhdGVTdXNwZW5kZWRZaWVsZDtcblxuICAgICAgICAgIGlmIChyZWNvcmQuYXJnID09PSBDb250aW51ZVNlbnRpbmVsKSB7XG4gICAgICAgICAgICBjb250aW51ZTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICByZXR1cm4ge1xuICAgICAgICAgICAgdmFsdWU6IHJlY29yZC5hcmcsXG4gICAgICAgICAgICBkb25lOiBjb250ZXh0LmRvbmVcbiAgICAgICAgICB9O1xuXG4gICAgICAgIH0gZWxzZSBpZiAocmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgICAgIHN0YXRlID0gR2VuU3RhdGVDb21wbGV0ZWQ7XG4gICAgICAgICAgLy8gRGlzcGF0Y2ggdGhlIGV4Y2VwdGlvbiBieSBsb29waW5nIGJhY2sgYXJvdW5kIHRvIHRoZVxuICAgICAgICAgIC8vIGNvbnRleHQuZGlzcGF0Y2hFeGNlcHRpb24oY29udGV4dC5hcmcpIGNhbGwgYWJvdmUuXG4gICAgICAgICAgY29udGV4dC5tZXRob2QgPSBcInRocm93XCI7XG4gICAgICAgICAgY29udGV4dC5hcmcgPSByZWNvcmQuYXJnO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfTtcbiAgfVxuXG4gIC8vIENhbGwgZGVsZWdhdGUuaXRlcmF0b3JbY29udGV4dC5tZXRob2RdKGNvbnRleHQuYXJnKSBhbmQgaGFuZGxlIHRoZVxuICAvLyByZXN1bHQsIGVpdGhlciBieSByZXR1cm5pbmcgYSB7IHZhbHVlLCBkb25lIH0gcmVzdWx0IGZyb20gdGhlXG4gIC8vIGRlbGVnYXRlIGl0ZXJhdG9yLCBvciBieSBtb2RpZnlpbmcgY29udGV4dC5tZXRob2QgYW5kIGNvbnRleHQuYXJnLFxuICAvLyBzZXR0aW5nIGNvbnRleHQuZGVsZWdhdGUgdG8gbnVsbCwgYW5kIHJldHVybmluZyB0aGUgQ29udGludWVTZW50aW5lbC5cbiAgZnVuY3Rpb24gbWF5YmVJbnZva2VEZWxlZ2F0ZShkZWxlZ2F0ZSwgY29udGV4dCkge1xuICAgIHZhciBtZXRob2QgPSBkZWxlZ2F0ZS5pdGVyYXRvcltjb250ZXh0Lm1ldGhvZF07XG4gICAgaWYgKG1ldGhvZCA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICAvLyBBIC50aHJvdyBvciAucmV0dXJuIHdoZW4gdGhlIGRlbGVnYXRlIGl0ZXJhdG9yIGhhcyBubyAudGhyb3dcbiAgICAgIC8vIG1ldGhvZCBhbHdheXMgdGVybWluYXRlcyB0aGUgeWllbGQqIGxvb3AuXG4gICAgICBjb250ZXh0LmRlbGVnYXRlID0gbnVsbDtcblxuICAgICAgaWYgKGNvbnRleHQubWV0aG9kID09PSBcInRocm93XCIpIHtcbiAgICAgICAgLy8gTm90ZTogW1wicmV0dXJuXCJdIG11c3QgYmUgdXNlZCBmb3IgRVMzIHBhcnNpbmcgY29tcGF0aWJpbGl0eS5cbiAgICAgICAgaWYgKGRlbGVnYXRlLml0ZXJhdG9yW1wicmV0dXJuXCJdKSB7XG4gICAgICAgICAgLy8gSWYgdGhlIGRlbGVnYXRlIGl0ZXJhdG9yIGhhcyBhIHJldHVybiBtZXRob2QsIGdpdmUgaXQgYVxuICAgICAgICAgIC8vIGNoYW5jZSB0byBjbGVhbiB1cC5cbiAgICAgICAgICBjb250ZXh0Lm1ldGhvZCA9IFwicmV0dXJuXCI7XG4gICAgICAgICAgY29udGV4dC5hcmcgPSB1bmRlZmluZWQ7XG4gICAgICAgICAgbWF5YmVJbnZva2VEZWxlZ2F0ZShkZWxlZ2F0ZSwgY29udGV4dCk7XG5cbiAgICAgICAgICBpZiAoY29udGV4dC5tZXRob2QgPT09IFwidGhyb3dcIikge1xuICAgICAgICAgICAgLy8gSWYgbWF5YmVJbnZva2VEZWxlZ2F0ZShjb250ZXh0KSBjaGFuZ2VkIGNvbnRleHQubWV0aG9kIGZyb21cbiAgICAgICAgICAgIC8vIFwicmV0dXJuXCIgdG8gXCJ0aHJvd1wiLCBsZXQgdGhhdCBvdmVycmlkZSB0aGUgVHlwZUVycm9yIGJlbG93LlxuICAgICAgICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgY29udGV4dC5tZXRob2QgPSBcInRocm93XCI7XG4gICAgICAgIGNvbnRleHQuYXJnID0gbmV3IFR5cGVFcnJvcihcbiAgICAgICAgICBcIlRoZSBpdGVyYXRvciBkb2VzIG5vdCBwcm92aWRlIGEgJ3Rocm93JyBtZXRob2RcIik7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgIH1cblxuICAgIHZhciByZWNvcmQgPSB0cnlDYXRjaChtZXRob2QsIGRlbGVnYXRlLml0ZXJhdG9yLCBjb250ZXh0LmFyZyk7XG5cbiAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgY29udGV4dC5tZXRob2QgPSBcInRocm93XCI7XG4gICAgICBjb250ZXh0LmFyZyA9IHJlY29yZC5hcmc7XG4gICAgICBjb250ZXh0LmRlbGVnYXRlID0gbnVsbDtcbiAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgIH1cblxuICAgIHZhciBpbmZvID0gcmVjb3JkLmFyZztcblxuICAgIGlmICghIGluZm8pIHtcbiAgICAgIGNvbnRleHQubWV0aG9kID0gXCJ0aHJvd1wiO1xuICAgICAgY29udGV4dC5hcmcgPSBuZXcgVHlwZUVycm9yKFwiaXRlcmF0b3IgcmVzdWx0IGlzIG5vdCBhbiBvYmplY3RcIik7XG4gICAgICBjb250ZXh0LmRlbGVnYXRlID0gbnVsbDtcbiAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgIH1cblxuICAgIGlmIChpbmZvLmRvbmUpIHtcbiAgICAgIC8vIEFzc2lnbiB0aGUgcmVzdWx0IG9mIHRoZSBmaW5pc2hlZCBkZWxlZ2F0ZSB0byB0aGUgdGVtcG9yYXJ5XG4gICAgICAvLyB2YXJpYWJsZSBzcGVjaWZpZWQgYnkgZGVsZWdhdGUucmVzdWx0TmFtZSAoc2VlIGRlbGVnYXRlWWllbGQpLlxuICAgICAgY29udGV4dFtkZWxlZ2F0ZS5yZXN1bHROYW1lXSA9IGluZm8udmFsdWU7XG5cbiAgICAgIC8vIFJlc3VtZSBleGVjdXRpb24gYXQgdGhlIGRlc2lyZWQgbG9jYXRpb24gKHNlZSBkZWxlZ2F0ZVlpZWxkKS5cbiAgICAgIGNvbnRleHQubmV4dCA9IGRlbGVnYXRlLm5leHRMb2M7XG5cbiAgICAgIC8vIElmIGNvbnRleHQubWV0aG9kIHdhcyBcInRocm93XCIgYnV0IHRoZSBkZWxlZ2F0ZSBoYW5kbGVkIHRoZVxuICAgICAgLy8gZXhjZXB0aW9uLCBsZXQgdGhlIG91dGVyIGdlbmVyYXRvciBwcm9jZWVkIG5vcm1hbGx5LiBJZlxuICAgICAgLy8gY29udGV4dC5tZXRob2Qgd2FzIFwibmV4dFwiLCBmb3JnZXQgY29udGV4dC5hcmcgc2luY2UgaXQgaGFzIGJlZW5cbiAgICAgIC8vIFwiY29uc3VtZWRcIiBieSB0aGUgZGVsZWdhdGUgaXRlcmF0b3IuIElmIGNvbnRleHQubWV0aG9kIHdhc1xuICAgICAgLy8gXCJyZXR1cm5cIiwgYWxsb3cgdGhlIG9yaWdpbmFsIC5yZXR1cm4gY2FsbCB0byBjb250aW51ZSBpbiB0aGVcbiAgICAgIC8vIG91dGVyIGdlbmVyYXRvci5cbiAgICAgIGlmIChjb250ZXh0Lm1ldGhvZCAhPT0gXCJyZXR1cm5cIikge1xuICAgICAgICBjb250ZXh0Lm1ldGhvZCA9IFwibmV4dFwiO1xuICAgICAgICBjb250ZXh0LmFyZyA9IHVuZGVmaW5lZDtcbiAgICAgIH1cblxuICAgIH0gZWxzZSB7XG4gICAgICAvLyBSZS15aWVsZCB0aGUgcmVzdWx0IHJldHVybmVkIGJ5IHRoZSBkZWxlZ2F0ZSBtZXRob2QuXG4gICAgICByZXR1cm4gaW5mbztcbiAgICB9XG5cbiAgICAvLyBUaGUgZGVsZWdhdGUgaXRlcmF0b3IgaXMgZmluaXNoZWQsIHNvIGZvcmdldCBpdCBhbmQgY29udGludWUgd2l0aFxuICAgIC8vIHRoZSBvdXRlciBnZW5lcmF0b3IuXG4gICAgY29udGV4dC5kZWxlZ2F0ZSA9IG51bGw7XG4gICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gIH1cblxuICAvLyBEZWZpbmUgR2VuZXJhdG9yLnByb3RvdHlwZS57bmV4dCx0aHJvdyxyZXR1cm59IGluIHRlcm1zIG9mIHRoZVxuICAvLyB1bmlmaWVkIC5faW52b2tlIGhlbHBlciBtZXRob2QuXG4gIGRlZmluZUl0ZXJhdG9yTWV0aG9kcyhHcCk7XG5cbiAgZGVmaW5lKEdwLCB0b1N0cmluZ1RhZ1N5bWJvbCwgXCJHZW5lcmF0b3JcIik7XG5cbiAgLy8gQSBHZW5lcmF0b3Igc2hvdWxkIGFsd2F5cyByZXR1cm4gaXRzZWxmIGFzIHRoZSBpdGVyYXRvciBvYmplY3Qgd2hlbiB0aGVcbiAgLy8gQEBpdGVyYXRvciBmdW5jdGlvbiBpcyBjYWxsZWQgb24gaXQuIFNvbWUgYnJvd3NlcnMnIGltcGxlbWVudGF0aW9ucyBvZiB0aGVcbiAgLy8gaXRlcmF0b3IgcHJvdG90eXBlIGNoYWluIGluY29ycmVjdGx5IGltcGxlbWVudCB0aGlzLCBjYXVzaW5nIHRoZSBHZW5lcmF0b3JcbiAgLy8gb2JqZWN0IHRvIG5vdCBiZSByZXR1cm5lZCBmcm9tIHRoaXMgY2FsbC4gVGhpcyBlbnN1cmVzIHRoYXQgZG9lc24ndCBoYXBwZW4uXG4gIC8vIFNlZSBodHRwczovL2dpdGh1Yi5jb20vZmFjZWJvb2svcmVnZW5lcmF0b3IvaXNzdWVzLzI3NCBmb3IgbW9yZSBkZXRhaWxzLlxuICBHcFtpdGVyYXRvclN5bWJvbF0gPSBmdW5jdGlvbigpIHtcbiAgICByZXR1cm4gdGhpcztcbiAgfTtcblxuICBHcC50b1N0cmluZyA9IGZ1bmN0aW9uKCkge1xuICAgIHJldHVybiBcIltvYmplY3QgR2VuZXJhdG9yXVwiO1xuICB9O1xuXG4gIGZ1bmN0aW9uIHB1c2hUcnlFbnRyeShsb2NzKSB7XG4gICAgdmFyIGVudHJ5ID0geyB0cnlMb2M6IGxvY3NbMF0gfTtcblxuICAgIGlmICgxIGluIGxvY3MpIHtcbiAgICAgIGVudHJ5LmNhdGNoTG9jID0gbG9jc1sxXTtcbiAgICB9XG5cbiAgICBpZiAoMiBpbiBsb2NzKSB7XG4gICAgICBlbnRyeS5maW5hbGx5TG9jID0gbG9jc1syXTtcbiAgICAgIGVudHJ5LmFmdGVyTG9jID0gbG9jc1szXTtcbiAgICB9XG5cbiAgICB0aGlzLnRyeUVudHJpZXMucHVzaChlbnRyeSk7XG4gIH1cblxuICBmdW5jdGlvbiByZXNldFRyeUVudHJ5KGVudHJ5KSB7XG4gICAgdmFyIHJlY29yZCA9IGVudHJ5LmNvbXBsZXRpb24gfHwge307XG4gICAgcmVjb3JkLnR5cGUgPSBcIm5vcm1hbFwiO1xuICAgIGRlbGV0ZSByZWNvcmQuYXJnO1xuICAgIGVudHJ5LmNvbXBsZXRpb24gPSByZWNvcmQ7XG4gIH1cblxuICBmdW5jdGlvbiBDb250ZXh0KHRyeUxvY3NMaXN0KSB7XG4gICAgLy8gVGhlIHJvb3QgZW50cnkgb2JqZWN0IChlZmZlY3RpdmVseSBhIHRyeSBzdGF0ZW1lbnQgd2l0aG91dCBhIGNhdGNoXG4gICAgLy8gb3IgYSBmaW5hbGx5IGJsb2NrKSBnaXZlcyB1cyBhIHBsYWNlIHRvIHN0b3JlIHZhbHVlcyB0aHJvd24gZnJvbVxuICAgIC8vIGxvY2F0aW9ucyB3aGVyZSB0aGVyZSBpcyBubyBlbmNsb3NpbmcgdHJ5IHN0YXRlbWVudC5cbiAgICB0aGlzLnRyeUVudHJpZXMgPSBbeyB0cnlMb2M6IFwicm9vdFwiIH1dO1xuICAgIHRyeUxvY3NMaXN0LmZvckVhY2gocHVzaFRyeUVudHJ5LCB0aGlzKTtcbiAgICB0aGlzLnJlc2V0KHRydWUpO1xuICB9XG5cbiAgZXhwb3J0cy5rZXlzID0gZnVuY3Rpb24ob2JqZWN0KSB7XG4gICAgdmFyIGtleXMgPSBbXTtcbiAgICBmb3IgKHZhciBrZXkgaW4gb2JqZWN0KSB7XG4gICAgICBrZXlzLnB1c2goa2V5KTtcbiAgICB9XG4gICAga2V5cy5yZXZlcnNlKCk7XG5cbiAgICAvLyBSYXRoZXIgdGhhbiByZXR1cm5pbmcgYW4gb2JqZWN0IHdpdGggYSBuZXh0IG1ldGhvZCwgd2Uga2VlcFxuICAgIC8vIHRoaW5ncyBzaW1wbGUgYW5kIHJldHVybiB0aGUgbmV4dCBmdW5jdGlvbiBpdHNlbGYuXG4gICAgcmV0dXJuIGZ1bmN0aW9uIG5leHQoKSB7XG4gICAgICB3aGlsZSAoa2V5cy5sZW5ndGgpIHtcbiAgICAgICAgdmFyIGtleSA9IGtleXMucG9wKCk7XG4gICAgICAgIGlmIChrZXkgaW4gb2JqZWN0KSB7XG4gICAgICAgICAgbmV4dC52YWx1ZSA9IGtleTtcbiAgICAgICAgICBuZXh0LmRvbmUgPSBmYWxzZTtcbiAgICAgICAgICByZXR1cm4gbmV4dDtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICAvLyBUbyBhdm9pZCBjcmVhdGluZyBhbiBhZGRpdGlvbmFsIG9iamVjdCwgd2UganVzdCBoYW5nIHRoZSAudmFsdWVcbiAgICAgIC8vIGFuZCAuZG9uZSBwcm9wZXJ0aWVzIG9mZiB0aGUgbmV4dCBmdW5jdGlvbiBvYmplY3QgaXRzZWxmLiBUaGlzXG4gICAgICAvLyBhbHNvIGVuc3VyZXMgdGhhdCB0aGUgbWluaWZpZXIgd2lsbCBub3QgYW5vbnltaXplIHRoZSBmdW5jdGlvbi5cbiAgICAgIG5leHQuZG9uZSA9IHRydWU7XG4gICAgICByZXR1cm4gbmV4dDtcbiAgICB9O1xuICB9O1xuXG4gIGZ1bmN0aW9uIHZhbHVlcyhpdGVyYWJsZSkge1xuICAgIGlmIChpdGVyYWJsZSkge1xuICAgICAgdmFyIGl0ZXJhdG9yTWV0aG9kID0gaXRlcmFibGVbaXRlcmF0b3JTeW1ib2xdO1xuICAgICAgaWYgKGl0ZXJhdG9yTWV0aG9kKSB7XG4gICAgICAgIHJldHVybiBpdGVyYXRvck1ldGhvZC5jYWxsKGl0ZXJhYmxlKTtcbiAgICAgIH1cblxuICAgICAgaWYgKHR5cGVvZiBpdGVyYWJsZS5uZXh0ID09PSBcImZ1bmN0aW9uXCIpIHtcbiAgICAgICAgcmV0dXJuIGl0ZXJhYmxlO1xuICAgICAgfVxuXG4gICAgICBpZiAoIWlzTmFOKGl0ZXJhYmxlLmxlbmd0aCkpIHtcbiAgICAgICAgdmFyIGkgPSAtMSwgbmV4dCA9IGZ1bmN0aW9uIG5leHQoKSB7XG4gICAgICAgICAgd2hpbGUgKCsraSA8IGl0ZXJhYmxlLmxlbmd0aCkge1xuICAgICAgICAgICAgaWYgKGhhc093bi5jYWxsKGl0ZXJhYmxlLCBpKSkge1xuICAgICAgICAgICAgICBuZXh0LnZhbHVlID0gaXRlcmFibGVbaV07XG4gICAgICAgICAgICAgIG5leHQuZG9uZSA9IGZhbHNlO1xuICAgICAgICAgICAgICByZXR1cm4gbmV4dDtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG5cbiAgICAgICAgICBuZXh0LnZhbHVlID0gdW5kZWZpbmVkO1xuICAgICAgICAgIG5leHQuZG9uZSA9IHRydWU7XG5cbiAgICAgICAgICByZXR1cm4gbmV4dDtcbiAgICAgICAgfTtcblxuICAgICAgICByZXR1cm4gbmV4dC5uZXh0ID0gbmV4dDtcbiAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBSZXR1cm4gYW4gaXRlcmF0b3Igd2l0aCBubyB2YWx1ZXMuXG4gICAgcmV0dXJuIHsgbmV4dDogZG9uZVJlc3VsdCB9O1xuICB9XG4gIGV4cG9ydHMudmFsdWVzID0gdmFsdWVzO1xuXG4gIGZ1bmN0aW9uIGRvbmVSZXN1bHQoKSB7XG4gICAgcmV0dXJuIHsgdmFsdWU6IHVuZGVmaW5lZCwgZG9uZTogdHJ1ZSB9O1xuICB9XG5cbiAgQ29udGV4dC5wcm90b3R5cGUgPSB7XG4gICAgY29uc3RydWN0b3I6IENvbnRleHQsXG5cbiAgICByZXNldDogZnVuY3Rpb24oc2tpcFRlbXBSZXNldCkge1xuICAgICAgdGhpcy5wcmV2ID0gMDtcbiAgICAgIHRoaXMubmV4dCA9IDA7XG4gICAgICAvLyBSZXNldHRpbmcgY29udGV4dC5fc2VudCBmb3IgbGVnYWN5IHN1cHBvcnQgb2YgQmFiZWwnc1xuICAgICAgLy8gZnVuY3Rpb24uc2VudCBpbXBsZW1lbnRhdGlvbi5cbiAgICAgIHRoaXMuc2VudCA9IHRoaXMuX3NlbnQgPSB1bmRlZmluZWQ7XG4gICAgICB0aGlzLmRvbmUgPSBmYWxzZTtcbiAgICAgIHRoaXMuZGVsZWdhdGUgPSBudWxsO1xuXG4gICAgICB0aGlzLm1ldGhvZCA9IFwibmV4dFwiO1xuICAgICAgdGhpcy5hcmcgPSB1bmRlZmluZWQ7XG5cbiAgICAgIHRoaXMudHJ5RW50cmllcy5mb3JFYWNoKHJlc2V0VHJ5RW50cnkpO1xuXG4gICAgICBpZiAoIXNraXBUZW1wUmVzZXQpIHtcbiAgICAgICAgZm9yICh2YXIgbmFtZSBpbiB0aGlzKSB7XG4gICAgICAgICAgLy8gTm90IHN1cmUgYWJvdXQgdGhlIG9wdGltYWwgb3JkZXIgb2YgdGhlc2UgY29uZGl0aW9uczpcbiAgICAgICAgICBpZiAobmFtZS5jaGFyQXQoMCkgPT09IFwidFwiICYmXG4gICAgICAgICAgICAgIGhhc093bi5jYWxsKHRoaXMsIG5hbWUpICYmXG4gICAgICAgICAgICAgICFpc05hTigrbmFtZS5zbGljZSgxKSkpIHtcbiAgICAgICAgICAgIHRoaXNbbmFtZV0gPSB1bmRlZmluZWQ7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfSxcblxuICAgIHN0b3A6IGZ1bmN0aW9uKCkge1xuICAgICAgdGhpcy5kb25lID0gdHJ1ZTtcblxuICAgICAgdmFyIHJvb3RFbnRyeSA9IHRoaXMudHJ5RW50cmllc1swXTtcbiAgICAgIHZhciByb290UmVjb3JkID0gcm9vdEVudHJ5LmNvbXBsZXRpb247XG4gICAgICBpZiAocm9vdFJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgICAgdGhyb3cgcm9vdFJlY29yZC5hcmc7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiB0aGlzLnJ2YWw7XG4gICAgfSxcblxuICAgIGRpc3BhdGNoRXhjZXB0aW9uOiBmdW5jdGlvbihleGNlcHRpb24pIHtcbiAgICAgIGlmICh0aGlzLmRvbmUpIHtcbiAgICAgICAgdGhyb3cgZXhjZXB0aW9uO1xuICAgICAgfVxuXG4gICAgICB2YXIgY29udGV4dCA9IHRoaXM7XG4gICAgICBmdW5jdGlvbiBoYW5kbGUobG9jLCBjYXVnaHQpIHtcbiAgICAgICAgcmVjb3JkLnR5cGUgPSBcInRocm93XCI7XG4gICAgICAgIHJlY29yZC5hcmcgPSBleGNlcHRpb247XG4gICAgICAgIGNvbnRleHQubmV4dCA9IGxvYztcblxuICAgICAgICBpZiAoY2F1Z2h0KSB7XG4gICAgICAgICAgLy8gSWYgdGhlIGRpc3BhdGNoZWQgZXhjZXB0aW9uIHdhcyBjYXVnaHQgYnkgYSBjYXRjaCBibG9jayxcbiAgICAgICAgICAvLyB0aGVuIGxldCB0aGF0IGNhdGNoIGJsb2NrIGhhbmRsZSB0aGUgZXhjZXB0aW9uIG5vcm1hbGx5LlxuICAgICAgICAgIGNvbnRleHQubWV0aG9kID0gXCJuZXh0XCI7XG4gICAgICAgICAgY29udGV4dC5hcmcgPSB1bmRlZmluZWQ7XG4gICAgICAgIH1cblxuICAgICAgICByZXR1cm4gISEgY2F1Z2h0O1xuICAgICAgfVxuXG4gICAgICBmb3IgKHZhciBpID0gdGhpcy50cnlFbnRyaWVzLmxlbmd0aCAtIDE7IGkgPj0gMDsgLS1pKSB7XG4gICAgICAgIHZhciBlbnRyeSA9IHRoaXMudHJ5RW50cmllc1tpXTtcbiAgICAgICAgdmFyIHJlY29yZCA9IGVudHJ5LmNvbXBsZXRpb247XG5cbiAgICAgICAgaWYgKGVudHJ5LnRyeUxvYyA9PT0gXCJyb290XCIpIHtcbiAgICAgICAgICAvLyBFeGNlcHRpb24gdGhyb3duIG91dHNpZGUgb2YgYW55IHRyeSBibG9jayB0aGF0IGNvdWxkIGhhbmRsZVxuICAgICAgICAgIC8vIGl0LCBzbyBzZXQgdGhlIGNvbXBsZXRpb24gdmFsdWUgb2YgdGhlIGVudGlyZSBmdW5jdGlvbiB0b1xuICAgICAgICAgIC8vIHRocm93IHRoZSBleGNlcHRpb24uXG4gICAgICAgICAgcmV0dXJuIGhhbmRsZShcImVuZFwiKTtcbiAgICAgICAgfVxuXG4gICAgICAgIGlmIChlbnRyeS50cnlMb2MgPD0gdGhpcy5wcmV2KSB7XG4gICAgICAgICAgdmFyIGhhc0NhdGNoID0gaGFzT3duLmNhbGwoZW50cnksIFwiY2F0Y2hMb2NcIik7XG4gICAgICAgICAgdmFyIGhhc0ZpbmFsbHkgPSBoYXNPd24uY2FsbChlbnRyeSwgXCJmaW5hbGx5TG9jXCIpO1xuXG4gICAgICAgICAgaWYgKGhhc0NhdGNoICYmIGhhc0ZpbmFsbHkpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLnByZXYgPCBlbnRyeS5jYXRjaExvYykge1xuICAgICAgICAgICAgICByZXR1cm4gaGFuZGxlKGVudHJ5LmNhdGNoTG9jLCB0cnVlKTtcbiAgICAgICAgICAgIH0gZWxzZSBpZiAodGhpcy5wcmV2IDwgZW50cnkuZmluYWxseUxvYykge1xuICAgICAgICAgICAgICByZXR1cm4gaGFuZGxlKGVudHJ5LmZpbmFsbHlMb2MpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgfSBlbHNlIGlmIChoYXNDYXRjaCkge1xuICAgICAgICAgICAgaWYgKHRoaXMucHJldiA8IGVudHJ5LmNhdGNoTG9jKSB7XG4gICAgICAgICAgICAgIHJldHVybiBoYW5kbGUoZW50cnkuY2F0Y2hMb2MsIHRydWUpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgfSBlbHNlIGlmIChoYXNGaW5hbGx5KSB7XG4gICAgICAgICAgICBpZiAodGhpcy5wcmV2IDwgZW50cnkuZmluYWxseUxvYykge1xuICAgICAgICAgICAgICByZXR1cm4gaGFuZGxlKGVudHJ5LmZpbmFsbHlMb2MpO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcInRyeSBzdGF0ZW1lbnQgd2l0aG91dCBjYXRjaCBvciBmaW5hbGx5XCIpO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0sXG5cbiAgICBhYnJ1cHQ6IGZ1bmN0aW9uKHR5cGUsIGFyZykge1xuICAgICAgZm9yICh2YXIgaSA9IHRoaXMudHJ5RW50cmllcy5sZW5ndGggLSAxOyBpID49IDA7IC0taSkge1xuICAgICAgICB2YXIgZW50cnkgPSB0aGlzLnRyeUVudHJpZXNbaV07XG4gICAgICAgIGlmIChlbnRyeS50cnlMb2MgPD0gdGhpcy5wcmV2ICYmXG4gICAgICAgICAgICBoYXNPd24uY2FsbChlbnRyeSwgXCJmaW5hbGx5TG9jXCIpICYmXG4gICAgICAgICAgICB0aGlzLnByZXYgPCBlbnRyeS5maW5hbGx5TG9jKSB7XG4gICAgICAgICAgdmFyIGZpbmFsbHlFbnRyeSA9IGVudHJ5O1xuICAgICAgICAgIGJyZWFrO1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIGlmIChmaW5hbGx5RW50cnkgJiZcbiAgICAgICAgICAodHlwZSA9PT0gXCJicmVha1wiIHx8XG4gICAgICAgICAgIHR5cGUgPT09IFwiY29udGludWVcIikgJiZcbiAgICAgICAgICBmaW5hbGx5RW50cnkudHJ5TG9jIDw9IGFyZyAmJlxuICAgICAgICAgIGFyZyA8PSBmaW5hbGx5RW50cnkuZmluYWxseUxvYykge1xuICAgICAgICAvLyBJZ25vcmUgdGhlIGZpbmFsbHkgZW50cnkgaWYgY29udHJvbCBpcyBub3QganVtcGluZyB0byBhXG4gICAgICAgIC8vIGxvY2F0aW9uIG91dHNpZGUgdGhlIHRyeS9jYXRjaCBibG9jay5cbiAgICAgICAgZmluYWxseUVudHJ5ID0gbnVsbDtcbiAgICAgIH1cblxuICAgICAgdmFyIHJlY29yZCA9IGZpbmFsbHlFbnRyeSA/IGZpbmFsbHlFbnRyeS5jb21wbGV0aW9uIDoge307XG4gICAgICByZWNvcmQudHlwZSA9IHR5cGU7XG4gICAgICByZWNvcmQuYXJnID0gYXJnO1xuXG4gICAgICBpZiAoZmluYWxseUVudHJ5KSB7XG4gICAgICAgIHRoaXMubWV0aG9kID0gXCJuZXh0XCI7XG4gICAgICAgIHRoaXMubmV4dCA9IGZpbmFsbHlFbnRyeS5maW5hbGx5TG9jO1xuICAgICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHRoaXMuY29tcGxldGUocmVjb3JkKTtcbiAgICB9LFxuXG4gICAgY29tcGxldGU6IGZ1bmN0aW9uKHJlY29yZCwgYWZ0ZXJMb2MpIHtcbiAgICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgIHRocm93IHJlY29yZC5hcmc7XG4gICAgICB9XG5cbiAgICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJicmVha1wiIHx8XG4gICAgICAgICAgcmVjb3JkLnR5cGUgPT09IFwiY29udGludWVcIikge1xuICAgICAgICB0aGlzLm5leHQgPSByZWNvcmQuYXJnO1xuICAgICAgfSBlbHNlIGlmIChyZWNvcmQudHlwZSA9PT0gXCJyZXR1cm5cIikge1xuICAgICAgICB0aGlzLnJ2YWwgPSB0aGlzLmFyZyA9IHJlY29yZC5hcmc7XG4gICAgICAgIHRoaXMubWV0aG9kID0gXCJyZXR1cm5cIjtcbiAgICAgICAgdGhpcy5uZXh0ID0gXCJlbmRcIjtcbiAgICAgIH0gZWxzZSBpZiAocmVjb3JkLnR5cGUgPT09IFwibm9ybWFsXCIgJiYgYWZ0ZXJMb2MpIHtcbiAgICAgICAgdGhpcy5uZXh0ID0gYWZ0ZXJMb2M7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgIH0sXG5cbiAgICBmaW5pc2g6IGZ1bmN0aW9uKGZpbmFsbHlMb2MpIHtcbiAgICAgIGZvciAodmFyIGkgPSB0aGlzLnRyeUVudHJpZXMubGVuZ3RoIC0gMTsgaSA+PSAwOyAtLWkpIHtcbiAgICAgICAgdmFyIGVudHJ5ID0gdGhpcy50cnlFbnRyaWVzW2ldO1xuICAgICAgICBpZiAoZW50cnkuZmluYWxseUxvYyA9PT0gZmluYWxseUxvYykge1xuICAgICAgICAgIHRoaXMuY29tcGxldGUoZW50cnkuY29tcGxldGlvbiwgZW50cnkuYWZ0ZXJMb2MpO1xuICAgICAgICAgIHJlc2V0VHJ5RW50cnkoZW50cnkpO1xuICAgICAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSxcblxuICAgIFwiY2F0Y2hcIjogZnVuY3Rpb24odHJ5TG9jKSB7XG4gICAgICBmb3IgKHZhciBpID0gdGhpcy50cnlFbnRyaWVzLmxlbmd0aCAtIDE7IGkgPj0gMDsgLS1pKSB7XG4gICAgICAgIHZhciBlbnRyeSA9IHRoaXMudHJ5RW50cmllc1tpXTtcbiAgICAgICAgaWYgKGVudHJ5LnRyeUxvYyA9PT0gdHJ5TG9jKSB7XG4gICAgICAgICAgdmFyIHJlY29yZCA9IGVudHJ5LmNvbXBsZXRpb247XG4gICAgICAgICAgaWYgKHJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgICAgICAgIHZhciB0aHJvd24gPSByZWNvcmQuYXJnO1xuICAgICAgICAgICAgcmVzZXRUcnlFbnRyeShlbnRyeSk7XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybiB0aHJvd247XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgLy8gVGhlIGNvbnRleHQuY2F0Y2ggbWV0aG9kIG11c3Qgb25seSBiZSBjYWxsZWQgd2l0aCBhIGxvY2F0aW9uXG4gICAgICAvLyBhcmd1bWVudCB0aGF0IGNvcnJlc3BvbmRzIHRvIGEga25vd24gY2F0Y2ggYmxvY2suXG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJpbGxlZ2FsIGNhdGNoIGF0dGVtcHRcIik7XG4gICAgfSxcblxuICAgIGRlbGVnYXRlWWllbGQ6IGZ1bmN0aW9uKGl0ZXJhYmxlLCByZXN1bHROYW1lLCBuZXh0TG9jKSB7XG4gICAgICB0aGlzLmRlbGVnYXRlID0ge1xuICAgICAgICBpdGVyYXRvcjogdmFsdWVzKGl0ZXJhYmxlKSxcbiAgICAgICAgcmVzdWx0TmFtZTogcmVzdWx0TmFtZSxcbiAgICAgICAgbmV4dExvYzogbmV4dExvY1xuICAgICAgfTtcblxuICAgICAgaWYgKHRoaXMubWV0aG9kID09PSBcIm5leHRcIikge1xuICAgICAgICAvLyBEZWxpYmVyYXRlbHkgZm9yZ2V0IHRoZSBsYXN0IHNlbnQgdmFsdWUgc28gdGhhdCB3ZSBkb24ndFxuICAgICAgICAvLyBhY2NpZGVudGFsbHkgcGFzcyBpdCBvbiB0byB0aGUgZGVsZWdhdGUuXG4gICAgICAgIHRoaXMuYXJnID0gdW5kZWZpbmVkO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICB9XG4gIH07XG5cbiAgLy8gUmVnYXJkbGVzcyBvZiB3aGV0aGVyIHRoaXMgc2NyaXB0IGlzIGV4ZWN1dGluZyBhcyBhIENvbW1vbkpTIG1vZHVsZVxuICAvLyBvciBub3QsIHJldHVybiB0aGUgcnVudGltZSBvYmplY3Qgc28gdGhhdCB3ZSBjYW4gZGVjbGFyZSB0aGUgdmFyaWFibGVcbiAgLy8gcmVnZW5lcmF0b3JSdW50aW1lIGluIHRoZSBvdXRlciBzY29wZSwgd2hpY2ggYWxsb3dzIHRoaXMgbW9kdWxlIHRvIGJlXG4gIC8vIGluamVjdGVkIGVhc2lseSBieSBgYmluL3JlZ2VuZXJhdG9yIC0taW5jbHVkZS1ydW50aW1lIHNjcmlwdC5qc2AuXG4gIHJldHVybiBleHBvcnRzO1xuXG59KFxuICAvLyBJZiB0aGlzIHNjcmlwdCBpcyBleGVjdXRpbmcgYXMgYSBDb21tb25KUyBtb2R1bGUsIHVzZSBtb2R1bGUuZXhwb3J0c1xuICAvLyBhcyB0aGUgcmVnZW5lcmF0b3JSdW50aW1lIG5hbWVzcGFjZS4gT3RoZXJ3aXNlIGNyZWF0ZSBhIG5ldyBlbXB0eVxuICAvLyBvYmplY3QuIEVpdGhlciB3YXksIHRoZSByZXN1bHRpbmcgb2JqZWN0IHdpbGwgYmUgdXNlZCB0byBpbml0aWFsaXplXG4gIC8vIHRoZSByZWdlbmVyYXRvclJ1bnRpbWUgdmFyaWFibGUgYXQgdGhlIHRvcCBvZiB0aGlzIGZpbGUuXG4gIHR5cGVvZiBtb2R1bGUgPT09IFwib2JqZWN0XCIgPyBtb2R1bGUuZXhwb3J0cyA6IHt9XG4pKTtcblxudHJ5IHtcbiAgcmVnZW5lcmF0b3JSdW50aW1lID0gcnVudGltZTtcbn0gY2F0Y2ggKGFjY2lkZW50YWxTdHJpY3RNb2RlKSB7XG4gIC8vIFRoaXMgbW9kdWxlIHNob3VsZCBub3QgYmUgcnVubmluZyBpbiBzdHJpY3QgbW9kZSwgc28gdGhlIGFib3ZlXG4gIC8vIGFzc2lnbm1lbnQgc2hvdWxkIGFsd2F5cyB3b3JrIHVubGVzcyBzb21ldGhpbmcgaXMgbWlzY29uZmlndXJlZC4gSnVzdFxuICAvLyBpbiBjYXNlIHJ1bnRpbWUuanMgYWNjaWRlbnRhbGx5IHJ1bnMgaW4gc3RyaWN0IG1vZGUsIHdlIGNhbiBlc2NhcGVcbiAgLy8gc3RyaWN0IG1vZGUgdXNpbmcgYSBnbG9iYWwgRnVuY3Rpb24gY2FsbC4gVGhpcyBjb3VsZCBjb25jZWl2YWJseSBmYWlsXG4gIC8vIGlmIGEgQ29udGVudCBTZWN1cml0eSBQb2xpY3kgZm9yYmlkcyB1c2luZyBGdW5jdGlvbiwgYnV0IGluIHRoYXQgY2FzZVxuICAvLyB0aGUgcHJvcGVyIHNvbHV0aW9uIGlzIHRvIGZpeCB0aGUgYWNjaWRlbnRhbCBzdHJpY3QgbW9kZSBwcm9ibGVtLiBJZlxuICAvLyB5b3UndmUgbWlzY29uZmlndXJlZCB5b3VyIGJ1bmRsZXIgdG8gZm9yY2Ugc3RyaWN0IG1vZGUgYW5kIGFwcGxpZWQgYVxuICAvLyBDU1AgdG8gZm9yYmlkIEZ1bmN0aW9uLCBhbmQgeW91J3JlIG5vdCB3aWxsaW5nIHRvIGZpeCBlaXRoZXIgb2YgdGhvc2VcbiAgLy8gcHJvYmxlbXMsIHBsZWFzZSBkZXRhaWwgeW91ciB1bmlxdWUgcHJlZGljYW1lbnQgaW4gYSBHaXRIdWIgaXNzdWUuXG4gIEZ1bmN0aW9uKFwiclwiLCBcInJlZ2VuZXJhdG9yUnVudGltZSA9IHJcIikocnVudGltZSk7XG59XG4iLCJtb2R1bGUuZXhwb3J0cyA9IHJlcXVpcmUoXCJyZWdlbmVyYXRvci1ydW50aW1lXCIpO1xuIiwiaW1wb3J0IHNpbXBsZUdpdCBmcm9tICdzaW1wbGUtZ2l0J1xuXG5pbXBvcnQgeyByZWFkQ2hhbmdlbG9nLCByZXF1aXJlRW52LCBzYXZlQ2hhbmdlbG9nIH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWNvcmUnXG5cbmNvbnN0IGZpbmFsaXplQ3VycmVudEVudHJ5ID0gYXN5bmMoY2hhbmdlbG9nKSA9PiB7XG4gIGNvbnN0IGN1cnJlbnRFbnRyeSA9IGNoYW5nZWxvZ1swXVxuXG4gIC8vIHVwZGF0ZSB0aGUgaW52b2x2ZWQgcHJvamVjdHNcbiAgY29uc3QgaW52b2x2ZWRQcm9qZWN0cyA9IHJlcXVpcmVFbnYoJ0lOVk9MVkVEX1BST0pFQ1RTJykuc3BsaXQoJ1xcbicpXG4gIGN1cnJlbnRFbnRyeS5pbnZvbHZlZFByb2plY3RzID0gaW52b2x2ZWRQcm9qZWN0c1xuXG4gIGNvbnN0IGJyYW5jaEZyb20gPSBjdXJyZW50RW50cnkuYnJhbmNoRnJvbVxuICBjb25zdCBnaXRPcHRpb25zID0ge1xuICAgIGJhc2VEaXIgICAgICAgICAgICAgICAgOiBwcm9jZXNzLmN3ZCgpLFxuICAgIGJpbmFyeSAgICAgICAgICAgICAgICAgOiAnZ2l0JyxcbiAgICBtYXhDb25jdXJyZW50UHJvY2Vzc2VzIDogNlxuICB9XG4gIGNvbnN0IGdpdCA9IHNpbXBsZUdpdChnaXRPcHRpb25zKVxuICBjb25zdCByZXN1bHRzID0gYXdhaXQgZ2l0LnJhdygnc2hvcnRsb2cnLCAnLS1zdW1tYXJ5JywgJy0tZW1haWwnLCBgJHticmFuY2hGcm9tfS4uLkhFQURgKVxuICBjb25zdCBjb250cmlidXRvcnMgPSByZXN1bHRzXG4gICAgLnNwbGl0KCdcXG4nKVxuICAgIC5tYXAoKGwpID0+IGwucmVwbGFjZSgvXltcXHNcXGRdK1xccysvLCAnJykpXG4gICAgLmZpbHRlcigobCkgPT4gbC5sZW5ndGggPiAwKVxuICBjdXJyZW50RW50cnkuY29udHJpYnV0b3JzID0gY29udHJpYnV0b3JzXG5cbiAgLypcbiAgXCJxYVwiOiB7XG4gICAgIFwidGVzdGVkVmVyc2lvblwiOiBcImJmODIwZTMxOC4uLlwiLFxuICAgICBcInVuaXRUZXN0UmVwb3J0XCI6IFwiaHR0cHM6Ly8uLi5cIixcbiAgICAgXCJsaW50UmVwb3J0XCI6IFwiaHR0cHM6Ly8uLi5cIlxuICB9XG4gICovXG4gIHJldHVybiBjdXJyZW50RW50cnlcbn1cblxuY29uc3QgZmluYWxpemVDaGFuZ2Vsb2cgPSBhc3luYygpID0+IHtcbiAgY29uc3QgY2hhbmdlbG9nID0gcmVhZENoYW5nZWxvZygpXG4gIGF3YWl0IGZpbmFsaXplQ3VycmVudEVudHJ5KGNoYW5nZWxvZylcbiAgc2F2ZUNoYW5nZWxvZyhjaGFuZ2Vsb2cpXG59XG5cbmV4cG9ydCB7IGZpbmFsaXplQ3VycmVudEVudHJ5LCBmaW5hbGl6ZUNoYW5nZWxvZyB9XG4iLCJpbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBwcmludEVudHJpZXMgPSAoaG90Zml4ZXMsIGxhc3RSZWxlYXNlRGF0ZSkgPT4ge1xuICBjb25zdCBjaGFuZ2Vsb2cgPSByZWFkQ2hhbmdlbG9nKClcblxuICAvLyBUT0RPOiB0aGlzIGlzIGEgYml0IG9mIGEgbGltaXRhdGlvbiByZXF1aXJpbmcgdGhlIHNjcmlwdCBwd2QgdG8gYmUgdGhlIHBhY2thZ2Ugcm9vdC5cbiAgY29uc3QgcGFja2FnZUNvbnRlbnRzID0gZnMucmVhZEZpbGVTeW5jKCdwYWNrYWdlLmpzb24nKVxuICBjb25zdCBwYWNrYWdlRGF0YSA9IEpTT04ucGFyc2UocGFja2FnZUNvbnRlbnRzKVxuXG4gIGNvbnN0IGNoYW5nZUVudHJpZXMgPSBjaGFuZ2Vsb2cubWFwKHIgPT4gKHsgdGltZSA6IG5ldyBEYXRlKHIuc3RhcnRUaW1lc3RhbXApLCBub3RlcyA6IHIuY2hhbmdlTm90ZXMsIGF1dGhvciA6IHIud29ya0luaXRpYXRvciB9KSlcbiAgICAuY29uY2F0KGhvdGZpeGVzLm1hcChyID0+IChcbiAgICAgIHtcbiAgICAgICAgdGltZSAgICAgOiBuZXcgRGF0ZShyLmRhdGUpLFxuICAgICAgICBub3RlcyAgICA6IFtyLm1lc3NhZ2UucmVwbGFjZSgvXlxccypob3RmaXhcXHMqOj9cXHMqL2ksICcnKV0sXG4gICAgICAgIGF1dGhvciAgIDogci5hdXRob3IuZW1haWwsXG4gICAgICAgIGlzSG90Zml4IDogdHJ1ZVxuICAgICAgfVxuICAgICkpKVxuICAgIC5maWx0ZXIociA9PiByLnRpbWUgPj0gbGFzdFJlbGVhc2VEYXRlKVxuICAvLyB3aXRoIERhdGVzLCB3ZSByZWFsbHkgd2FudCAnPT0nLCBub3QgJz09PSdcbiAgY2hhbmdlRW50cmllcy5zb3J0KChhLCBiKSA9PiBhLnRpbWUgPCBiLnRpbWUgPyAtMSA6IGEudGltZSA9PSBiLnRpbWUgPyAwIDogMSkgLy8gZXNsaW50LWRpc2FibGUtbGluZSBlcWVxZXFcblxuICBsZXQgc2VjdXJpdHlOb3RlcyA9IFtdXG4gIGxldCBkcnBCY3BOb3RlcyA9IFtdXG4gIGxldCBiYWNrb3V0Tm90ZXMgPSBbXVxuXG4gIGZvciAoY29uc3QgZW50cnkgb2YgY2hhbmdlbG9nKSB7XG4gICAgaWYgKGVudHJ5LnNlY3VyaXR5Tm90ZXMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgc2VjdXJpdHlOb3RlcyA9IHNlY3VyaXR5Tm90ZXMuY29uY2F0KGVudHJ5LnNlY3VyaXR5Tm90ZXMpXG4gICAgfVxuICAgIGlmIChlbnRyeS5kcnBCY3BOb3RlcyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICBkcnBCY3BOb3RlcyA9IGRycEJjcE5vdGVzLmNvbmNhdChlbnRyeS5kcnBCY3BOb3RlcylcbiAgICB9XG4gICAgaWYgKGVudHJ5LmJhY2tvdXROb3RlcyAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICBiYWNrb3V0Tm90ZXMgPSBiYWNrb3V0Tm90ZXMuY29uY2F0KGVudHJ5LmJhY2tvdXROb3RlcylcbiAgICB9XG4gIH1cblxuICBjb25zdCBhdHRyaWIgPSAoZW50cnkpID0+IGBfKCR7ZW50cnkuYXV0aG9yfTsgJHtlbnRyeS50aW1lLnRvSVNPU3RyaW5nKCl9KV9gXG5cbiAgZm9yIChjb25zdCBlbnRyeSBvZiBjaGFuZ2VFbnRyaWVzKSB7XG4gICAgaWYgKGVudHJ5LmlzSG90Zml4KSB7XG4gICAgICBjb25zb2xlLmxvZyhgKiBfKipob3RmaXgqKl86ICR7ZW50cnkubm90ZXNbMF19ICR7YXR0cmliKGVudHJ5KX1gKVxuICAgIH1cbiAgICBlbHNlIHtcbiAgICAgIGZvciAoY29uc3Qgbm90ZSBvZiBlbnRyeS5ub3Rlcykge1xuICAgICAgICBjb25zb2xlLmxvZyhgKiAke25vdGV9ICR7YXR0cmliKGVudHJ5KX1gKVxuICAgICAgfVxuICAgIH1cbiAgfVxuICBpZiAocGFja2FnZURhdGE/LmxpcT8uY29udHJhY3RzPy5zZWN1cmUgfHwgc2VjdXJpdHlOb3Rlcy5sZW5ndGggPiAwKSB7XG4gICAgY29uc29sZS5sb2coJ1xcbiMjIyBTZWN1cml0eSBub3Rlc1xcblxcbicpXG4gICAgY29uc29sZS5sb2coYCR7c2VjdXJpdHlOb3Rlcy5sZW5ndGggPT09IDAgPyAnX25vbmVfJyA6IGAqICR7c2VjdXJpdHlOb3Rlcy5qb2luKCdcXG4qICcpfWB9YClcbiAgfVxuICBpZiAoLyogVE9ETzogYW4gb3JnIHNldHRpbmcgb3JnLnNldHRpbmdzPy5bJ21haW50YWlucyBEUlAvQkNQJ10gfHwgKi8gZHJwQmNwTm90ZXMubGVuZ3RoID4gMCkge1xuICAgIGNvbnNvbGUubG9nKCdcXG4jIyMgRFJQL0JDUCBub3Rlc1xcblxcbicpXG4gICAgY29uc29sZS5sb2coYCR7ZHJwQmNwTm90ZXMubGVuZ3RoID09PSAwID8gJ19ub25lXycgOiBgKiAke2RycEJjcE5vdGVzLmpvaW4oJ1xcbiogJyl9YH1gKVxuICB9XG4gIGlmIChwYWNrYWdlRGF0YT8ubGlxPy5jb250cmFjdHM/LlsnaGlnaCBhdmFpbGFiaWxpdHknXSB8fCBiYWNrb3V0Tm90ZXMubGVuZ3RoID4gMCkge1xuICAgIGNvbnNvbGUubG9nKCdcXG4jIyMgQmFja291dCBub3Rlc1xcblxcbicpXG4gICAgY29uc29sZS5sb2coYCR7YmFja291dE5vdGVzLmxlbmd0aCA9PT0gMCA/ICdfbm9uZV8nIDogYCogJHtiYWNrb3V0Tm90ZXMuam9pbignXFxuKiAnKX1gfWApXG4gIH1cbn1cblxuZXhwb3J0IHsgcHJpbnRFbnRyaWVzIH1cbiIsImZ1bmN0aW9uIF9hcnJheVdpdGhIb2xlcyhhcnIpIHtcbiAgaWYgKEFycmF5LmlzQXJyYXkoYXJyKSkgcmV0dXJuIGFycjtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfYXJyYXlXaXRoSG9sZXM7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiZnVuY3Rpb24gX2l0ZXJhYmxlVG9BcnJheUxpbWl0KGFyciwgaSkge1xuICB2YXIgX2kgPSBhcnIgPT0gbnVsbCA/IG51bGwgOiB0eXBlb2YgU3ltYm9sICE9PSBcInVuZGVmaW5lZFwiICYmIGFycltTeW1ib2wuaXRlcmF0b3JdIHx8IGFycltcIkBAaXRlcmF0b3JcIl07XG5cbiAgaWYgKF9pID09IG51bGwpIHJldHVybjtcbiAgdmFyIF9hcnIgPSBbXTtcbiAgdmFyIF9uID0gdHJ1ZTtcbiAgdmFyIF9kID0gZmFsc2U7XG5cbiAgdmFyIF9zLCBfZTtcblxuICB0cnkge1xuICAgIGZvciAoX2kgPSBfaS5jYWxsKGFycik7ICEoX24gPSAoX3MgPSBfaS5uZXh0KCkpLmRvbmUpOyBfbiA9IHRydWUpIHtcbiAgICAgIF9hcnIucHVzaChfcy52YWx1ZSk7XG5cbiAgICAgIGlmIChpICYmIF9hcnIubGVuZ3RoID09PSBpKSBicmVhaztcbiAgICB9XG4gIH0gY2F0Y2ggKGVycikge1xuICAgIF9kID0gdHJ1ZTtcbiAgICBfZSA9IGVycjtcbiAgfSBmaW5hbGx5IHtcbiAgICB0cnkge1xuICAgICAgaWYgKCFfbiAmJiBfaVtcInJldHVyblwiXSAhPSBudWxsKSBfaVtcInJldHVyblwiXSgpO1xuICAgIH0gZmluYWxseSB7XG4gICAgICBpZiAoX2QpIHRocm93IF9lO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBfYXJyO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9pdGVyYWJsZVRvQXJyYXlMaW1pdDtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCJmdW5jdGlvbiBfYXJyYXlMaWtlVG9BcnJheShhcnIsIGxlbikge1xuICBpZiAobGVuID09IG51bGwgfHwgbGVuID4gYXJyLmxlbmd0aCkgbGVuID0gYXJyLmxlbmd0aDtcblxuICBmb3IgKHZhciBpID0gMCwgYXJyMiA9IG5ldyBBcnJheShsZW4pOyBpIDwgbGVuOyBpKyspIHtcbiAgICBhcnIyW2ldID0gYXJyW2ldO1xuICB9XG5cbiAgcmV0dXJuIGFycjI7XG59XG5cbm1vZHVsZS5leHBvcnRzID0gX2FycmF5TGlrZVRvQXJyYXk7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwidmFyIGFycmF5TGlrZVRvQXJyYXkgPSByZXF1aXJlKFwiLi9hcnJheUxpa2VUb0FycmF5LmpzXCIpO1xuXG5mdW5jdGlvbiBfdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkobywgbWluTGVuKSB7XG4gIGlmICghbykgcmV0dXJuO1xuICBpZiAodHlwZW9mIG8gPT09IFwic3RyaW5nXCIpIHJldHVybiBhcnJheUxpa2VUb0FycmF5KG8sIG1pbkxlbik7XG4gIHZhciBuID0gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZy5jYWxsKG8pLnNsaWNlKDgsIC0xKTtcbiAgaWYgKG4gPT09IFwiT2JqZWN0XCIgJiYgby5jb25zdHJ1Y3RvcikgbiA9IG8uY29uc3RydWN0b3IubmFtZTtcbiAgaWYgKG4gPT09IFwiTWFwXCIgfHwgbiA9PT0gXCJTZXRcIikgcmV0dXJuIEFycmF5LmZyb20obyk7XG4gIGlmIChuID09PSBcIkFyZ3VtZW50c1wiIHx8IC9eKD86VWl8SSludCg/Ojh8MTZ8MzIpKD86Q2xhbXBlZCk/QXJyYXkkLy50ZXN0KG4pKSByZXR1cm4gYXJyYXlMaWtlVG9BcnJheShvLCBtaW5MZW4pO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheTtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCJmdW5jdGlvbiBfbm9uSXRlcmFibGVSZXN0KCkge1xuICB0aHJvdyBuZXcgVHlwZUVycm9yKFwiSW52YWxpZCBhdHRlbXB0IHRvIGRlc3RydWN0dXJlIG5vbi1pdGVyYWJsZSBpbnN0YW5jZS5cXG5JbiBvcmRlciB0byBiZSBpdGVyYWJsZSwgbm9uLWFycmF5IG9iamVjdHMgbXVzdCBoYXZlIGEgW1N5bWJvbC5pdGVyYXRvcl0oKSBtZXRob2QuXCIpO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9ub25JdGVyYWJsZVJlc3Q7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwidmFyIGFycmF5V2l0aEhvbGVzID0gcmVxdWlyZShcIi4vYXJyYXlXaXRoSG9sZXMuanNcIik7XG5cbnZhciBpdGVyYWJsZVRvQXJyYXlMaW1pdCA9IHJlcXVpcmUoXCIuL2l0ZXJhYmxlVG9BcnJheUxpbWl0LmpzXCIpO1xuXG52YXIgdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkgPSByZXF1aXJlKFwiLi91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheS5qc1wiKTtcblxudmFyIG5vbkl0ZXJhYmxlUmVzdCA9IHJlcXVpcmUoXCIuL25vbkl0ZXJhYmxlUmVzdC5qc1wiKTtcblxuZnVuY3Rpb24gX3NsaWNlZFRvQXJyYXkoYXJyLCBpKSB7XG4gIHJldHVybiBhcnJheVdpdGhIb2xlcyhhcnIpIHx8IGl0ZXJhYmxlVG9BcnJheUxpbWl0KGFyciwgaSkgfHwgdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkoYXJyLCBpKSB8fCBub25JdGVyYWJsZVJlc3QoKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfc2xpY2VkVG9BcnJheTtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCIvLyBUT0RPOiBvbmNlIHdlJ3ZlIHVwZGF0ZWQgYWxsIG91ciBvbGQgJ2NoYW5nZWxvZy5qc29uJyBmb3JtYXRzLCB3ZSBjYW4gZHJvcCB0aGlzLiBUaGVyZSBhcmUgbm8gZXhhbXBsZXMgJ2luIHRoZSB3aWxkJyB0aGF0IHdlIG5lZWQgdG8gd29ycnkgYWJvdXQuXG5cbmltcG9ydCAqIGFzIGZzIGZyb20gJ2ZzJ1xuaW1wb3J0IHsgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCByZWFkT2xkQ2hhbmdlbG9nID0gKCkgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG4gIGNvbnN0IG9sZENsUGF0aCA9IGAke2NsUGF0aC5zdWJzdHJpbmcoMCwgY2xQYXRoLmxlbmd0aCAtIDUpfS5qc29uYFxuXG4gIGNvbnN0IG9sZENsQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMob2xkQ2xQYXRoKVxuICBjb25zdCBvbGRDbCA9IEpTT04ucGFyc2Uob2xkQ2xDb250ZW50cylcblxuICByZXR1cm4gb2xkQ2xcbn1cblxuY29uc3QgY29udmVydEZvcm1hdCA9IChjaGFuZ2Vsb2cpID0+IHtcbiAgY2hhbmdlbG9nLnJldmVyc2UoKSAvLyBpbi1wbGFjZSBtb2RpZmljYXRpb25cbiAgZm9yIChjb25zdCBlbnRyeSBvZiBjaGFuZ2Vsb2cpIHtcbiAgICBjb25zdCBuZXdTdGFydCA9IG5ldyBEYXRlKClcbiAgICBuZXdTdGFydC5zZXRUaW1lKDApXG4gICAgLy8gb2xkIGZvcm1hdDogVVRDOnl5eXktbW0tZGQtSEhNTSBaXG4gICAgY29uc3QgW3llYXIsIG1vbnRoLCBkYXRlLCB0aW1lXSA9IGVudHJ5LnN0YXJ0VGltZXN0YW1wTG9jYWwuc3BsaXQoJyAnKVswXS5zcGxpdCgnLScpXG4gICAgY29uc3QgaG91ciA9IHRpbWUuc3Vic3RyaW5nKDAsIDIpXG4gICAgY29uc3QgbWludXRlcyA9IHRpbWUuc3Vic3RyaW5nKDIpXG5cbiAgICBuZXdTdGFydC5zZXRVVENGdWxsWWVhcih5ZWFyKVxuICAgIG5ld1N0YXJ0LnNldFVUQ01vbnRoKG1vbnRoIC0gMSlcbiAgICBuZXdTdGFydC5zZXRVVENEYXRlKGRhdGUpXG4gICAgbmV3U3RhcnQuc2V0VVRDSG91cnMoaG91cilcbiAgICBuZXdTdGFydC5zZXRVVENNaW51dGVzKG1pbnV0ZXMpXG5cbiAgICBlbnRyeS5zdGFydFRpbWVzdGFtcCA9IG5ld1N0YXJ0LnRvSVNPU3RyaW5nKClcbiAgICBkZWxldGUgZW50cnkuc3RhcnRUaW1lc3RhbXBMb2NhbFxuXG4gICAgZW50cnkuc3RhcnRFcG9jaE1pbGxpcyA9IG5ld1N0YXJ0LmdldFRpbWUoKVxuXG4gICAgZW50cnkuY2hhbmdlTm90ZXMgPSBbZW50cnkuZGVzY3JpcHRpb25dXG4gICAgZGVsZXRlIGVudHJ5LmRlc2NyaXB0aW9uXG5cbiAgICBlbnRyeS5zZWN1cml0eU5vdGVzID0gW11cbiAgICBlbnRyeS5kcnBCY3BOb3RlcyA9IFtdXG4gICAgZW50cnkuYmFja291dE5vdGVzID0gW11cbiAgfVxuXG4gIHJldHVybiBjaGFuZ2Vsb2dcbn1cblxuY29uc3QgdXBkYXRlRmlsZUZvcm1hdCA9ICgpID0+IHtcbiAgY29uc3Qgb2xkQ2wgPSByZWFkT2xkQ2hhbmdlbG9nKClcbiAgY29uc3QgY2hhbmdlbG9nID0gY29udmVydEZvcm1hdChvbGRDbClcbiAgc2F2ZUNoYW5nZWxvZyhjaGFuZ2Vsb2cpXG59XG5cbmV4cG9ydCB7IGNvbnZlcnRGb3JtYXQsIHVwZGF0ZUZpbGVGb3JtYXQgfVxuIiwiaW1wb3J0IHsgYWRkRW50cnkgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctYWN0aW9uLWFkZC1lbnRyeSdcbmltcG9ydCB7IGZpbmFsaXplQ2hhbmdlbG9nIH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi1maW5hbGl6ZS1lbnRyeSdcbmltcG9ydCB7IHByaW50RW50cmllcyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1hY3Rpb24tcHJpbnQtZW50cmllcydcbmltcG9ydCB7IHVwZGF0ZUZpbGVGb3JtYXQgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctYWN0aW9uLXVwZGF0ZS1mb3JtYXQnXG5cbi8vIFNldHVwIHZhbGlkIGFjdGlvbnNcbmNvbnN0IEFERF9FTlRSWSA9ICdhZGQtZW50cnknXG5jb25zdCBGSU5BTElaRV9FTlRSWSA9ICdmaW5hbGl6ZS1lbnRyeSdcbmNvbnN0IFBSSU5UX0VOVFJJRVMgPSAncHJpbnQtZW50cmllcydcbmNvbnN0IFVQREFURV9GT1JNQVQgPSAndXBkYXRlLWZvcm1hdCdcbmNvbnN0IHZhbGlkQWN0aW9ucyA9IFtBRERfRU5UUlksIEZJTkFMSVpFX0VOVFJZLCBQUklOVF9FTlRSSUVTLCBVUERBVEVfRk9STUFUXVxuXG5jb25zdCBkZXRlcm1pbmVBY3Rpb24gPSAoKSA9PiB7XG4gIGNvbnN0IGFyZ3MgPSBwcm9jZXNzLmFyZ3Yuc2xpY2UoMilcblxuICBpZiAoYXJncy5sZW5ndGggPT09IDApIHsgLy8gfHwgYXJncy5sZW5ndGggPiAxKSB7IFRPRE86IHdlIGRvIG5lZWQgYXJncyBmb3IgJ3ByaW50LWNoYW5nZWxvZycuLi5cbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1VuZXhwZWN0ZWQgYXJndW1lbnQgY291bnQuIFBsZWFzZSBwcm92aWRlIGV4YWN0bHkgb25lIGFjdGlvbiBhcmd1bWVudC4nKVxuICB9XG5cbiAgY29uc3QgYWN0aW9uID0gYXJnc1swXVxuICBpZiAodmFsaWRBY3Rpb25zLmluZGV4T2YoYWN0aW9uKSA9PT0gLTEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYEludmFsaWQgYWN0aW9uOiAke2FjdGlvbn1gKVxuICB9XG5cbiAgc3dpdGNoIChhY3Rpb24pIHtcbiAgY2FzZSBBRERfRU5UUlk6XG4gICAgcmV0dXJuIGFkZEVudHJ5XG4gIGNhc2UgRklOQUxJWkVfRU5UUlk6XG4gICAgcmV0dXJuIGZpbmFsaXplQ2hhbmdlbG9nXG4gIGNhc2UgUFJJTlRfRU5UUklFUzpcbiAgICByZXR1cm4gKCkgPT4gcHJpbnRFbnRyaWVzKEpTT04ucGFyc2UoYXJnc1sxXSksIG5ldyBEYXRlKGFyZ3NbMl0pKVxuICBjYXNlIFVQREFURV9GT1JNQVQ6XG4gICAgcmV0dXJuIHVwZGF0ZUZpbGVGb3JtYXRcbiAgZGVmYXVsdDpcbiAgICB0aHJvdyBuZXcgRXJyb3IoYENhbm5vdCBwcm9jZXNzIHVua293biBhY3Rpb246ICR7YWN0aW9ufWApXG4gIH1cbn1cblxuY29uc3QgZXhlY3V0ZSA9ICgpID0+IHtcbiAgZGV0ZXJtaW5lQWN0aW9uKCkuY2FsbCgpXG59XG5cbmV4cG9ydCB7XG4gIGRldGVybWluZUFjdGlvbixcbiAgZXhlY3V0ZSxcbiAgdmFsaWRBY3Rpb25zXG59XG4iLCJpbXBvcnQgeyBleGVjdXRlIH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLXJ1bm5lcidcblxuZXhlY3V0ZSgpXG4iXSwibmFtZXMiOlsicmVhZENoYW5nZWxvZyIsImNsUGF0aGlzaCIsInJlcXVpcmVFbnYiLCJjbFBhdGgiLCJjaGFuZ2Vsb2dDb250ZW50cyIsImZzIiwicmVhZEZpbGVTeW5jIiwiY2hhbmdlbG9nIiwiWUFNTCIsInBhcnNlIiwia2V5IiwicHJvY2VzcyIsImVudiIsIkVycm9yIiwic2F2ZUNoYW5nZWxvZyIsInN0cmluZ2lmeSIsIndyaXRlRmlsZVN5bmMiLCJjcmVhdGVOZXdFbnRyeSIsIm5vdyIsIkRhdGUiLCJzdGFydFRpbWVzdGFtcCIsImRhdGVGb3JtYXQiLCJzdGFydEVwb2NoTWlsbGlzIiwiaXNzdWVzIiwic3BsaXQiLCJpbnZvbHZlZFByb2plY3RzIiwibmV3RW50cnkiLCJicmFuY2giLCJicmFuY2hGcm9tIiwid29ya0luaXRpYXRvciIsImJyYW5jaEluaXRpYXRvciIsImNoYW5nZU5vdGVzIiwic2VjdXJpdHlOb3RlcyIsImRycEJjcE5vdGVzIiwiYmFja291dE5vdGVzIiwicHVzaCIsImFkZEVudHJ5IiwidW5kZWZpbmVkIiwicmVxdWlyZSQkMCIsImZpbmFsaXplQ3VycmVudEVudHJ5IiwiY3VycmVudEVudHJ5IiwiZ2l0T3B0aW9ucyIsImJhc2VEaXIiLCJjd2QiLCJiaW5hcnkiLCJtYXhDb25jdXJyZW50UHJvY2Vzc2VzIiwiZ2l0Iiwic2ltcGxlR2l0IiwicmF3IiwicmVzdWx0cyIsImNvbnRyaWJ1dG9ycyIsIm1hcCIsImwiLCJyZXBsYWNlIiwiZmlsdGVyIiwibGVuZ3RoIiwiZmluYWxpemVDaGFuZ2Vsb2ciLCJwcmludEVudHJpZXMiLCJob3RmaXhlcyIsImxhc3RSZWxlYXNlRGF0ZSIsInBhY2thZ2VDb250ZW50cyIsInBhY2thZ2VEYXRhIiwiSlNPTiIsImNoYW5nZUVudHJpZXMiLCJyIiwidGltZSIsIm5vdGVzIiwiYXV0aG9yIiwiY29uY2F0IiwiZGF0ZSIsIm1lc3NhZ2UiLCJlbWFpbCIsImlzSG90Zml4Iiwic29ydCIsImEiLCJiIiwiZW50cnkiLCJhdHRyaWIiLCJ0b0lTT1N0cmluZyIsImNvbnNvbGUiLCJsb2ciLCJub3RlIiwibGlxIiwiY29udHJhY3RzIiwic2VjdXJlIiwiam9pbiIsInJlYWRPbGRDaGFuZ2Vsb2ciLCJvbGRDbFBhdGgiLCJzdWJzdHJpbmciLCJvbGRDbENvbnRlbnRzIiwib2xkQ2wiLCJjb252ZXJ0Rm9ybWF0IiwicmV2ZXJzZSIsIm5ld1N0YXJ0Iiwic2V0VGltZSIsInN0YXJ0VGltZXN0YW1wTG9jYWwiLCJ5ZWFyIiwibW9udGgiLCJob3VyIiwibWludXRlcyIsInNldFVUQ0Z1bGxZZWFyIiwic2V0VVRDTW9udGgiLCJzZXRVVENEYXRlIiwic2V0VVRDSG91cnMiLCJzZXRVVENNaW51dGVzIiwiZ2V0VGltZSIsImRlc2NyaXB0aW9uIiwidXBkYXRlRmlsZUZvcm1hdCIsIkFERF9FTlRSWSIsIkZJTkFMSVpFX0VOVFJZIiwiUFJJTlRfRU5UUklFUyIsIlVQREFURV9GT1JNQVQiLCJ2YWxpZEFjdGlvbnMiLCJkZXRlcm1pbmVBY3Rpb24iLCJhcmdzIiwiYXJndiIsInNsaWNlIiwiYWN0aW9uIiwiaW5kZXhPZiIsImV4ZWN1dGUiLCJjYWxsIl0sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7O0FBR0EsSUFBTUEsYUFBYSxHQUFHLFNBQWhCQSxhQUFnQixHQUFNO0FBQzFCLE1BQU1DLFNBQVMsR0FBR0MsVUFBVSxDQUFDLGdCQUFELENBQTVCO0FBQ0EsTUFBTUMsTUFBTSxHQUFHRixTQUFTLEtBQUssR0FBZCxHQUFvQixDQUFwQixHQUF3QkEsU0FBdkM7QUFFQSxNQUFNRyxpQkFBaUIsR0FBR0MsYUFBRSxDQUFDQyxZQUFILENBQWdCSCxNQUFoQixFQUF3QixNQUF4QixDQUExQixDQUowQjs7QUFLMUIsTUFBTUksU0FBUyxHQUFHQyx3QkFBSSxDQUFDQyxLQUFMLENBQVdMLGlCQUFYLENBQWxCO0FBRUEsU0FBT0csU0FBUDtBQUNELENBUkQ7O0FBVUEsSUFBTUwsVUFBVSxHQUFHLFNBQWJBLFVBQWEsQ0FBQ1EsR0FBRCxFQUFTO0FBQzFCLFNBQU9DLE9BQU8sQ0FBQ0MsR0FBUixDQUFZRixHQUFaO0FBQUE7QUFBQSxJQUEwQixJQUFJRyxLQUFKLHdEQUEwREgsR0FBMUQsRUFBMUIsQ0FBUDtBQUNELENBRkQ7O0FBSUEsSUFBTUksYUFBYSxHQUFHLFNBQWhCQSxhQUFnQixDQUFDUCxTQUFELEVBQWU7QUFDbkMsTUFBTUosTUFBTSxHQUFHRCxVQUFVLENBQUMsZ0JBQUQsQ0FBekI7QUFFQSxNQUFNRSxpQkFBaUIsR0FBR0ksd0JBQUksQ0FBQ08sU0FBTCxDQUFlUixTQUFmLENBQTFCO0FBQ0FGLEVBQUFBLGFBQUUsQ0FBQ1csYUFBSCxDQUFpQmIsTUFBakIsRUFBeUJDLGlCQUF6QjtBQUNELENBTEQ7O0FDYkEsSUFBTWEsY0FBYyxHQUFHLFNBQWpCQSxjQUFpQixDQUFDVixTQUFELEVBQWU7QUFDcEM7QUFDQSxNQUFNVyxHQUFHLEdBQUcsSUFBSUMsSUFBSixFQUFaO0FBQ0EsTUFBTUMsY0FB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
