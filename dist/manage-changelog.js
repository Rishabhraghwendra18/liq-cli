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
  });
  changeEntries.sort(function (a, b) {
    return a.time < b.time ? -1 : a.time == b.time ? 0 : 1;
  });
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
    console.log("\n### Security notes\n\n");
    console.log("".concat(securityNotes.length === 0 ? '_none_' : "* ".concat(securityNotes.join("\n* "))));
  }

  if (
  /* TODO: an org setting org.settings?.['maintains DRP/BCP'] ||*/
  drpBcpNotes.length > 0) {
    console.log("\n### DRP/BCP notes\n\n");
    console.log("".concat(drpBcpNotes.length === 0 ? '_none_' : "* ".concat(drpBcpNotes.join("\n* "))));
  }

  if (packageData !== null && packageData !== void 0 && (_packageData$liq2 = packageData.liq) !== null && _packageData$liq2 !== void 0 && (_packageData$liq2$con = _packageData$liq2.contracts) !== null && _packageData$liq2$con !== void 0 && _packageData$liq2$con['high availability'] || backoutNotes.length > 0) {
    console.log("\n### Backout notes\n\n");
    console.log("".concat(backoutNotes.length === 0 ? '_none_' : "* ".concat(backoutNotes.join("\n* "))));
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

      var hour = time.substring(0, 1);
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFuYWdlLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvY2hhbmdlbG9nL2xpYi1jaGFuZ2Vsb2ctY29yZS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9hc3luY1RvR2VuZXJhdG9yLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3JlZ2VuZXJhdG9yLXJ1bnRpbWUvcnVudGltZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9yZWdlbmVyYXRvci9pbmRleC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1maW5hbGl6ZS1lbnRyeS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1wcmludC1lbnRyaWVzLmpzIiwiLi4vbm9kZV9tb2R1bGVzL0BiYWJlbC9ydW50aW1lL2hlbHBlcnMvYXJyYXlXaXRoSG9sZXMuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9pdGVyYWJsZVRvQXJyYXlMaW1pdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL2FycmF5TGlrZVRvQXJyYXkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL25vbkl0ZXJhYmxlUmVzdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL3NsaWNlZFRvQXJyYXkuanMiLCIuLi9zcmMvbGlxL2FjdGlvbnMvd29yay9jaGFuZ2Vsb2cvbGliLWNoYW5nZWxvZy1hY3Rpb24tdXBkYXRlLWZvcm1hdC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLXJ1bm5lci5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9pbmRleC5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcbmltcG9ydCBZQU1MIGZyb20gJ3lhbWwnXG5cbmNvbnN0IHJlYWRDaGFuZ2Vsb2cgPSAoKSA9PiB7XG4gIGNvbnN0IGNsUGF0aGlzaCA9IHJlcXVpcmVFbnYoJ0NIQU5HRUxPR19GSUxFJylcbiAgY29uc3QgY2xQYXRoID0gY2xQYXRoaXNoID09PSAnLScgPyAwIDogY2xQYXRoaXNoXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoY2xQYXRoLCAndXRmOCcpIC8vIGluY2x1ZGUgZW5jb2RpbmcgdG8gZ2V0ICdzdHJpbmcnIHJlc3VsdFxuICBjb25zdCBjaGFuZ2Vsb2cgPSBZQU1MLnBhcnNlKGNoYW5nZWxvZ0NvbnRlbnRzKVxuXG4gIHJldHVybiBjaGFuZ2Vsb2dcbn1cblxuY29uc3QgcmVxdWlyZUVudiA9IChrZXkpID0+IHtcbiAgcmV0dXJuIHByb2Nlc3MuZW52W2tleV0gfHwgdGhyb3cgbmV3IEVycm9yKGBEaWQgbm90IGZpbmQgcmVxdWlyZWQgZW52aXJvbm1lbnQgcGFyYW1ldGVyOiAke2tleX1gKVxufVxuXG5jb25zdCBzYXZlQ2hhbmdlbG9nID0gKGNoYW5nZWxvZykgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBZQU1MLnN0cmluZ2lmeShjaGFuZ2Vsb2cpXG4gIGZzLndyaXRlRmlsZVN5bmMoY2xQYXRoLCBjaGFuZ2Vsb2dDb250ZW50cylcbn1cblxuZXhwb3J0IHtcbiAgcmVhZENoYW5nZWxvZyxcbiAgcmVxdWlyZUVudixcbiAgc2F2ZUNoYW5nZWxvZ1xufVxuIiwiaW1wb3J0IGRhdGVGb3JtYXQgZnJvbSAnZGF0ZWZvcm1hdCdcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZywgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBjcmVhdGVOZXdFbnRyeSA9IChjaGFuZ2Vsb2cpID0+IHtcbiAgLy8gZ2V0IHRoZSBhcHByb3ggc3RhcnQgdGltZSBhY2NvcmRpbmcgdG8gdGhlIGxvY2FsIGNsb2NrXG4gIGNvbnN0IG5vdyA9IG5ldyBEYXRlKClcbiAgY29uc3Qgc3RhcnRUaW1lc3RhbXAgPSBkYXRlRm9ybWF0KG5vdywgJ1VUQzp5eXl5LW1tLWRkLUhITU0uc3MgWicpXG4gIGNvbnN0IHN0YXJ0RXBvY2hNaWxsaXMgPSBub3cubm93KClcbiAgLy8gcHJvY2VzcyB0aGUgJ3dvcmsgdW5pdCcgZGF0YVxuICBjb25zdCBpc3N1ZXMgPSByZXF1aXJlRW52KCdXT1JLX0lTU1VFUycpLnNwbGl0KCdcXG4nKVxuICBjb25zdCBpbnZvbHZlZFByb2plY3RzID0gcmVxdWlyZUVudignSU5WT0xWRURfUFJPSkVDVFMnKS5zcGxpdCgnXFxuJylcblxuICBjb25zdCBuZXdFbnRyeSA9IHtcbiAgICBzdGFydFRpbWVzdGFtcCxcbiAgICBzdGFydEVwb2NoTWlsbGlzLFxuICAgIGlzc3VlcyxcbiAgICBicmFuY2ggICAgICAgICAgOiByZXF1aXJlRW52KCdXT1JLX0JSQU5DSCcpLFxuICAgIGJyYW5jaEZyb20gICAgICA6IHJlcXVpcmVFbnYoJ0NVUlJfUkVQT19WRVJTSU9OJyksXG4gICAgd29ya0luaXRpYXRvciAgIDogcmVxdWlyZUVudignV09SS19JTklUSUFUT1InKSxcbiAgICBicmFuY2hJbml0aWF0b3IgOiByZXF1aXJlRW52KCdDVVJSX1VTRVInKSxcbiAgICBpbnZvbHZlZFByb2plY3RzLFxuICAgIGNoYW5nZU5vdGVzICAgICA6IFsgcmVxdWlyZUVudignV09SS19ERVNDJykgXSxcbiAgICBzZWN1cml0eU5vdGVzICAgOiBbXSxcbiAgICBkcnBCY3BOb3RlcyAgICAgOiBbXSxcbiAgICBiYWNrb3V0Tm90ZXMgICAgOiBbXVxuICB9XG5cbiAgY2hhbmdlbG9nLnB1c2gobmV3RW50cnkpXG4gIHJldHVybiBuZXdFbnRyeVxufVxuXG5jb25zdCBhZGRFbnRyeSA9ICgpID0+IHtcbiAgY29uc3QgY2hhbmdlbG9nID0gcmVhZENoYW5nZWxvZygpXG4gIGNyZWF0ZU5ld0VudHJ5KGNoYW5nZWxvZylcbiAgc2F2ZUNoYW5nZWxvZyhjaGFuZ2Vsb2cpXG59XG5cbmV4cG9ydCB7IGFkZEVudHJ5LCBjcmVhdGVOZXdFbnRyeSB9XG4iLCJmdW5jdGlvbiBhc3luY0dlbmVyYXRvclN0ZXAoZ2VuLCByZXNvbHZlLCByZWplY3QsIF9uZXh0LCBfdGhyb3csIGtleSwgYXJnKSB7XG4gIHRyeSB7XG4gICAgdmFyIGluZm8gPSBnZW5ba2V5XShhcmcpO1xuICAgIHZhciB2YWx1ZSA9IGluZm8udmFsdWU7XG4gIH0gY2F0Y2ggKGVycm9yKSB7XG4gICAgcmVqZWN0KGVycm9yKTtcbiAgICByZXR1cm47XG4gIH1cblxuICBpZiAoaW5mby5kb25lKSB7XG4gICAgcmVzb2x2ZSh2YWx1ZSk7XG4gIH0gZWxzZSB7XG4gICAgUHJvbWlzZS5yZXNvbHZlKHZhbHVlKS50aGVuKF9uZXh0LCBfdGhyb3cpO1xuICB9XG59XG5cbmZ1bmN0aW9uIF9hc3luY1RvR2VuZXJhdG9yKGZuKSB7XG4gIHJldHVybiBmdW5jdGlvbiAoKSB7XG4gICAgdmFyIHNlbGYgPSB0aGlzLFxuICAgICAgICBhcmdzID0gYXJndW1lbnRzO1xuICAgIHJldHVybiBuZXcgUHJvbWlzZShmdW5jdGlvbiAocmVzb2x2ZSwgcmVqZWN0KSB7XG4gICAgICB2YXIgZ2VuID0gZm4uYXBwbHkoc2VsZiwgYXJncyk7XG5cbiAgICAgIGZ1bmN0aW9uIF9uZXh0KHZhbHVlKSB7XG4gICAgICAgIGFzeW5jR2VuZXJhdG9yU3RlcChnZW4sIHJlc29sdmUsIHJlamVjdCwgX25leHQsIF90aHJvdywgXCJuZXh0XCIsIHZhbHVlKTtcbiAgICAgIH1cblxuICAgICAgZnVuY3Rpb24gX3Rocm93KGVycikge1xuICAgICAgICBhc3luY0dlbmVyYXRvclN0ZXAoZ2VuLCByZXNvbHZlLCByZWplY3QsIF9uZXh0LCBfdGhyb3csIFwidGhyb3dcIiwgZXJyKTtcbiAgICAgIH1cblxuICAgICAgX25leHQodW5kZWZpbmVkKTtcbiAgICB9KTtcbiAgfTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfYXN5bmNUb0dlbmVyYXRvcjtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCIvKipcbiAqIENvcHlyaWdodCAoYykgMjAxNC1wcmVzZW50LCBGYWNlYm9vaywgSW5jLlxuICpcbiAqIFRoaXMgc291cmNlIGNvZGUgaXMgbGljZW5zZWQgdW5kZXIgdGhlIE1JVCBsaWNlbnNlIGZvdW5kIGluIHRoZVxuICogTElDRU5TRSBmaWxlIGluIHRoZSByb290IGRpcmVjdG9yeSBvZiB0aGlzIHNvdXJjZSB0cmVlLlxuICovXG5cbnZhciBydW50aW1lID0gKGZ1bmN0aW9uIChleHBvcnRzKSB7XG4gIFwidXNlIHN0cmljdFwiO1xuXG4gIHZhciBPcCA9IE9iamVjdC5wcm90b3R5cGU7XG4gIHZhciBoYXNPd24gPSBPcC5oYXNPd25Qcm9wZXJ0eTtcbiAgdmFyIHVuZGVmaW5lZDsgLy8gTW9yZSBjb21wcmVzc2libGUgdGhhbiB2b2lkIDAuXG4gIHZhciAkU3ltYm9sID0gdHlwZW9mIFN5bWJvbCA9PT0gXCJmdW5jdGlvblwiID8gU3ltYm9sIDoge307XG4gIHZhciBpdGVyYXRvclN5bWJvbCA9ICRTeW1ib2wuaXRlcmF0b3IgfHwgXCJAQGl0ZXJhdG9yXCI7XG4gIHZhciBhc3luY0l0ZXJhdG9yU3ltYm9sID0gJFN5bWJvbC5hc3luY0l0ZXJhdG9yIHx8IFwiQEBhc3luY0l0ZXJhdG9yXCI7XG4gIHZhciB0b1N0cmluZ1RhZ1N5bWJvbCA9ICRTeW1ib2wudG9TdHJpbmdUYWcgfHwgXCJAQHRvU3RyaW5nVGFnXCI7XG5cbiAgZnVuY3Rpb24gZGVmaW5lKG9iaiwga2V5LCB2YWx1ZSkge1xuICAgIE9iamVjdC5kZWZpbmVQcm9wZXJ0eShvYmosIGtleSwge1xuICAgICAgdmFsdWU6IHZhbHVlLFxuICAgICAgZW51bWVyYWJsZTogdHJ1ZSxcbiAgICAgIGNvbmZpZ3VyYWJsZTogdHJ1ZSxcbiAgICAgIHdyaXRhYmxlOiB0cnVlXG4gICAgfSk7XG4gICAgcmV0dXJuIG9ialtrZXldO1xuICB9XG4gIHRyeSB7XG4gICAgLy8gSUUgOCBoYXMgYSBicm9rZW4gT2JqZWN0LmRlZmluZVByb3BlcnR5IHRoYXQgb25seSB3b3JrcyBvbiBET00gb2JqZWN0cy5cbiAgICBkZWZpbmUoe30sIFwiXCIpO1xuICB9IGNhdGNoIChlcnIpIHtcbiAgICBkZWZpbmUgPSBmdW5jdGlvbihvYmosIGtleSwgdmFsdWUpIHtcbiAgICAgIHJldHVybiBvYmpba2V5XSA9IHZhbHVlO1xuICAgIH07XG4gIH1cblxuICBmdW5jdGlvbiB3cmFwKGlubmVyRm4sIG91dGVyRm4sIHNlbGYsIHRyeUxvY3NMaXN0KSB7XG4gICAgLy8gSWYgb3V0ZXJGbiBwcm92aWRlZCBhbmQgb3V0ZXJGbi5wcm90b3R5cGUgaXMgYSBHZW5lcmF0b3IsIHRoZW4gb3V0ZXJGbi5wcm90b3R5cGUgaW5zdGFuY2VvZiBHZW5lcmF0b3IuXG4gICAgdmFyIHByb3RvR2VuZXJhdG9yID0gb3V0ZXJGbiAmJiBvdXRlckZuLnByb3RvdHlwZSBpbnN0YW5jZW9mIEdlbmVyYXRvciA/IG91dGVyRm4gOiBHZW5lcmF0b3I7XG4gICAgdmFyIGdlbmVyYXRvciA9IE9iamVjdC5jcmVhdGUocHJvdG9HZW5lcmF0b3IucHJvdG90eXBlKTtcbiAgICB2YXIgY29udGV4dCA9IG5ldyBDb250ZXh0KHRyeUxvY3NMaXN0IHx8IFtdKTtcblxuICAgIC8vIFRoZSAuX2ludm9rZSBtZXRob2QgdW5pZmllcyB0aGUgaW1wbGVtZW50YXRpb25zIG9mIHRoZSAubmV4dCxcbiAgICAvLyAudGhyb3csIGFuZCAucmV0dXJuIG1ldGhvZHMuXG4gICAgZ2VuZXJhdG9yLl9pbnZva2UgPSBtYWtlSW52b2tlTWV0aG9kKGlubmVyRm4sIHNlbGYsIGNvbnRleHQpO1xuXG4gICAgcmV0dXJuIGdlbmVyYXRvcjtcbiAgfVxuICBleHBvcnRzLndyYXAgPSB3cmFwO1xuXG4gIC8vIFRyeS9jYXRjaCBoZWxwZXIgdG8gbWluaW1pemUgZGVvcHRpbWl6YXRpb25zLiBSZXR1cm5zIGEgY29tcGxldGlvblxuICAvLyByZWNvcmQgbGlrZSBjb250ZXh0LnRyeUVudHJpZXNbaV0uY29tcGxldGlvbi4gVGhpcyBpbnRlcmZhY2UgY291bGRcbiAgLy8gaGF2ZSBiZWVuIChhbmQgd2FzIHByZXZpb3VzbHkpIGRlc2lnbmVkIHRvIHRha2UgYSBjbG9zdXJlIHRvIGJlXG4gIC8vIGludm9rZWQgd2l0aG91dCBhcmd1bWVudHMsIGJ1dCBpbiBhbGwgdGhlIGNhc2VzIHdlIGNhcmUgYWJvdXQgd2VcbiAgLy8gYWxyZWFkeSBoYXZlIGFuIGV4aXN0aW5nIG1ldGhvZCB3ZSB3YW50IHRvIGNhbGwsIHNvIHRoZXJlJ3Mgbm8gbmVlZFxuICAvLyB0byBjcmVhdGUgYSBuZXcgZnVuY3Rpb24gb2JqZWN0LiBXZSBjYW4gZXZlbiBnZXQgYXdheSB3aXRoIGFzc3VtaW5nXG4gIC8vIHRoZSBtZXRob2QgdGFrZXMgZXhhY3RseSBvbmUgYXJndW1lbnQsIHNpbmNlIHRoYXQgaGFwcGVucyB0byBiZSB0cnVlXG4gIC8vIGluIGV2ZXJ5IGNhc2UsIHNvIHdlIGRvbid0IGhhdmUgdG8gdG91Y2ggdGhlIGFyZ3VtZW50cyBvYmplY3QuIFRoZVxuICAvLyBvbmx5IGFkZGl0aW9uYWwgYWxsb2NhdGlvbiByZXF1aXJlZCBpcyB0aGUgY29tcGxldGlvbiByZWNvcmQsIHdoaWNoXG4gIC8vIGhhcyBhIHN0YWJsZSBzaGFwZSBhbmQgc28gaG9wZWZ1bGx5IHNob3VsZCBiZSBjaGVhcCB0byBhbGxvY2F0ZS5cbiAgZnVuY3Rpb24gdHJ5Q2F0Y2goZm4sIG9iaiwgYXJnKSB7XG4gICAgdHJ5IHtcbiAgICAgIHJldHVybiB7IHR5cGU6IFwibm9ybWFsXCIsIGFyZzogZm4uY2FsbChvYmosIGFyZykgfTtcbiAgICB9IGNhdGNoIChlcnIpIHtcbiAgICAgIHJldHVybiB7IHR5cGU6IFwidGhyb3dcIiwgYXJnOiBlcnIgfTtcbiAgICB9XG4gIH1cblxuICB2YXIgR2VuU3RhdGVTdXNwZW5kZWRTdGFydCA9IFwic3VzcGVuZGVkU3RhcnRcIjtcbiAgdmFyIEdlblN0YXRlU3VzcGVuZGVkWWllbGQgPSBcInN1c3BlbmRlZFlpZWxkXCI7XG4gIHZhciBHZW5TdGF0ZUV4ZWN1dGluZyA9IFwiZXhlY3V0aW5nXCI7XG4gIHZhciBHZW5TdGF0ZUNvbXBsZXRlZCA9IFwiY29tcGxldGVkXCI7XG5cbiAgLy8gUmV0dXJuaW5nIHRoaXMgb2JqZWN0IGZyb20gdGhlIGlubmVyRm4gaGFzIHRoZSBzYW1lIGVmZmVjdCBhc1xuICAvLyBicmVha2luZyBvdXQgb2YgdGhlIGRpc3BhdGNoIHN3aXRjaCBzdGF0ZW1lbnQuXG4gIHZhciBDb250aW51ZVNlbnRpbmVsID0ge307XG5cbiAgLy8gRHVtbXkgY29uc3RydWN0b3IgZnVuY3Rpb25zIHRoYXQgd2UgdXNlIGFzIHRoZSAuY29uc3RydWN0b3IgYW5kXG4gIC8vIC5jb25zdHJ1Y3Rvci5wcm90b3R5cGUgcHJvcGVydGllcyBmb3IgZnVuY3Rpb25zIHRoYXQgcmV0dXJuIEdlbmVyYXRvclxuICAvLyBvYmplY3RzLiBGb3IgZnVsbCBzcGVjIGNvbXBsaWFuY2UsIHlvdSBtYXkgd2lzaCB0byBjb25maWd1cmUgeW91clxuICAvLyBtaW5pZmllciBub3QgdG8gbWFuZ2xlIHRoZSBuYW1lcyBvZiB0aGVzZSB0d28gZnVuY3Rpb25zLlxuICBmdW5jdGlvbiBHZW5lcmF0b3IoKSB7fVxuICBmdW5jdGlvbiBHZW5lcmF0b3JGdW5jdGlvbigpIHt9XG4gIGZ1bmN0aW9uIEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlKCkge31cblxuICAvLyBUaGlzIGlzIGEgcG9seWZpbGwgZm9yICVJdGVyYXRvclByb3RvdHlwZSUgZm9yIGVudmlyb25tZW50cyB0aGF0XG4gIC8vIGRvbid0IG5hdGl2ZWx5IHN1cHBvcnQgaXQuXG4gIHZhciBJdGVyYXRvclByb3RvdHlwZSA9IHt9O1xuICBJdGVyYXRvclByb3RvdHlwZVtpdGVyYXRvclN5bWJvbF0gPSBmdW5jdGlvbiAoKSB7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH07XG5cbiAgdmFyIGdldFByb3RvID0gT2JqZWN0LmdldFByb3RvdHlwZU9mO1xuICB2YXIgTmF0aXZlSXRlcmF0b3JQcm90b3R5cGUgPSBnZXRQcm90byAmJiBnZXRQcm90byhnZXRQcm90byh2YWx1ZXMoW10pKSk7XG4gIGlmIChOYXRpdmVJdGVyYXRvclByb3RvdHlwZSAmJlxuICAgICAgTmF0aXZlSXRlcmF0b3JQcm90b3R5cGUgIT09IE9wICYmXG4gICAgICBoYXNPd24uY2FsbChOYXRpdmVJdGVyYXRvclByb3RvdHlwZSwgaXRlcmF0b3JTeW1ib2wpKSB7XG4gICAgLy8gVGhpcyBlbnZpcm9ubWVudCBoYXMgYSBuYXRpdmUgJUl0ZXJhdG9yUHJvdG90eXBlJTsgdXNlIGl0IGluc3RlYWRcbiAgICAvLyBvZiB0aGUgcG9seWZpbGwuXG4gICAgSXRlcmF0b3JQcm90b3R5cGUgPSBOYXRpdmVJdGVyYXRvclByb3RvdHlwZTtcbiAgfVxuXG4gIHZhciBHcCA9IEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlLnByb3RvdHlwZSA9XG4gICAgR2VuZXJhdG9yLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoSXRlcmF0b3JQcm90b3R5cGUpO1xuICBHZW5lcmF0b3JGdW5jdGlvbi5wcm90b3R5cGUgPSBHcC5jb25zdHJ1Y3RvciA9IEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlO1xuICBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZS5jb25zdHJ1Y3RvciA9IEdlbmVyYXRvckZ1bmN0aW9uO1xuICBHZW5lcmF0b3JGdW5jdGlvbi5kaXNwbGF5TmFtZSA9IGRlZmluZShcbiAgICBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZSxcbiAgICB0b1N0cmluZ1RhZ1N5bWJvbCxcbiAgICBcIkdlbmVyYXRvckZ1bmN0aW9uXCJcbiAgKTtcblxuICAvLyBIZWxwZXIgZm9yIGRlZmluaW5nIHRoZSAubmV4dCwgLnRocm93LCBhbmQgLnJldHVybiBtZXRob2RzIG9mIHRoZVxuICAvLyBJdGVyYXRvciBpbnRlcmZhY2UgaW4gdGVybXMgb2YgYSBzaW5nbGUgLl9pbnZva2UgbWV0aG9kLlxuICBmdW5jdGlvbiBkZWZpbmVJdGVyYXRvck1ldGhvZHMocHJvdG90eXBlKSB7XG4gICAgW1wibmV4dFwiLCBcInRocm93XCIsIFwicmV0dXJuXCJdLmZvckVhY2goZnVuY3Rpb24obWV0aG9kKSB7XG4gICAgICBkZWZpbmUocHJvdG90eXBlLCBtZXRob2QsIGZ1bmN0aW9uKGFyZykge1xuICAgICAgICByZXR1cm4gdGhpcy5faW52b2tlKG1ldGhvZCwgYXJnKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgZXhwb3J0cy5pc0dlbmVyYXRvckZ1bmN0aW9uID0gZnVuY3Rpb24oZ2VuRnVuKSB7XG4gICAgdmFyIGN0b3IgPSB0eXBlb2YgZ2VuRnVuID09PSBcImZ1bmN0aW9uXCIgJiYgZ2VuRnVuLmNvbnN0cnVjdG9yO1xuICAgIHJldHVybiBjdG9yXG4gICAgICA/IGN0b3IgPT09IEdlbmVyYXRvckZ1bmN0aW9uIHx8XG4gICAgICAgIC8vIEZvciB0aGUgbmF0aXZlIEdlbmVyYXRvckZ1bmN0aW9uIGNvbnN0cnVjdG9yLCB0aGUgYmVzdCB3ZSBjYW5cbiAgICAgICAgLy8gZG8gaXMgdG8gY2hlY2sgaXRzIC5uYW1lIHByb3BlcnR5LlxuICAgICAgICAoY3Rvci5kaXNwbGF5TmFtZSB8fCBjdG9yLm5hbWUpID09PSBcIkdlbmVyYXRvckZ1bmN0aW9uXCJcbiAgICAgIDogZmFsc2U7XG4gIH07XG5cbiAgZXhwb3J0cy5tYXJrID0gZnVuY3Rpb24oZ2VuRnVuKSB7XG4gICAgaWYgKE9iamVjdC5zZXRQcm90b3R5cGVPZikge1xuICAgICAgT2JqZWN0LnNldFByb3RvdHlwZU9mKGdlbkZ1biwgR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGUpO1xuICAgIH0gZWxzZSB7XG4gICAgICBnZW5GdW4uX19wcm90b19fID0gR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGU7XG4gICAgICBkZWZpbmUoZ2VuRnVuLCB0b1N0cmluZ1RhZ1N5bWJvbCwgXCJHZW5lcmF0b3JGdW5jdGlvblwiKTtcbiAgICB9XG4gICAgZ2VuRnVuLnByb3RvdHlwZSA9IE9iamVjdC5jcmVhdGUoR3ApO1xuICAgIHJldHVybiBnZW5GdW47XG4gIH07XG5cbiAgLy8gV2l0aGluIHRoZSBib2R5IG9mIGFueSBhc3luYyBmdW5jdGlvbiwgYGF3YWl0IHhgIGlzIHRyYW5zZm9ybWVkIHRvXG4gIC8vIGB5aWVsZCByZWdlbmVyYXRvclJ1bnRpbWUuYXdyYXAoeClgLCBzbyB0aGF0IHRoZSBydW50aW1lIGNhbiB0ZXN0XG4gIC8vIGBoYXNPd24uY2FsbCh2YWx1ZSwgXCJfX2F3YWl0XCIpYCB0byBkZXRlcm1pbmUgaWYgdGhlIHlpZWxkZWQgdmFsdWUgaXNcbiAgLy8gbWVhbnQgdG8gYmUgYXdhaXRlZC5cbiAgZXhwb3J0cy5hd3JhcCA9IGZ1bmN0aW9uKGFyZykge1xuICAgIHJldHVybiB7IF9fYXdhaXQ6IGFyZyB9O1xuICB9O1xuXG4gIGZ1bmN0aW9uIEFzeW5jSXRlcmF0b3IoZ2VuZXJhdG9yLCBQcm9taXNlSW1wbCkge1xuICAgIGZ1bmN0aW9uIGludm9rZShtZXRob2QsIGFyZywgcmVzb2x2ZSwgcmVqZWN0KSB7XG4gICAgICB2YXIgcmVjb3JkID0gdHJ5Q2F0Y2goZ2VuZXJhdG9yW21ldGhvZF0sIGdlbmVyYXRvciwgYXJnKTtcbiAgICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgIHJlamVjdChyZWNvcmQuYXJnKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHZhciByZXN1bHQgPSByZWNvcmQuYXJnO1xuICAgICAgICB2YXIgdmFsdWUgPSByZXN1bHQudmFsdWU7XG4gICAgICAgIGlmICh2YWx1ZSAmJlxuICAgICAgICAgICAgdHlwZW9mIHZhbHVlID09PSBcIm9iamVjdFwiICYmXG4gICAgICAgICAgICBoYXNPd24uY2FsbCh2YWx1ZSwgXCJfX2F3YWl0XCIpKSB7XG4gICAgICAgICAgcmV0dXJuIFByb21pc2VJbXBsLnJlc29sdmUodmFsdWUuX19hd2FpdCkudGhlbihmdW5jdGlvbih2YWx1ZSkge1xuICAgICAgICAgICAgaW52b2tlKFwibmV4dFwiLCB2YWx1ZSwgcmVzb2x2ZSwgcmVqZWN0KTtcbiAgICAgICAgICB9LCBmdW5jdGlvbihlcnIpIHtcbiAgICAgICAgICAgIGludm9rZShcInRocm93XCIsIGVyciwgcmVzb2x2ZSwgcmVqZWN0KTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiBQcm9taXNlSW1wbC5yZXNvbHZlKHZhbHVlKS50aGVuKGZ1bmN0aW9uKHVud3JhcHBlZCkge1xuICAgICAgICAgIC8vIFdoZW4gYSB5aWVsZGVkIFByb21pc2UgaXMgcmVzb2x2ZWQsIGl0cyBmaW5hbCB2YWx1ZSBiZWNvbWVzXG4gICAgICAgICAgLy8gdGhlIC52YWx1ZSBvZiB0aGUgUHJvbWlzZTx7dmFsdWUsZG9uZX0+IHJlc3VsdCBmb3IgdGhlXG4gICAgICAgICAgLy8gY3VycmVudCBpdGVyYXRpb24uXG4gICAgICAgICAgcmVzdWx0LnZhbHVlID0gdW53cmFwcGVkO1xuICAgICAgICAgIHJlc29sdmUocmVzdWx0KTtcbiAgICAgICAgfSwgZnVuY3Rpb24oZXJyb3IpIHtcbiAgICAgICAgICAvLyBJZiBhIHJlamVjdGVkIFByb21pc2Ugd2FzIHlpZWxkZWQsIHRocm93IHRoZSByZWplY3Rpb24gYmFja1xuICAgICAgICAgIC8vIGludG8gdGhlIGFzeW5jIGdlbmVyYXRvciBmdW5jdGlvbiBzbyBpdCBjYW4gYmUgaGFuZGxlZCB0aGVyZS5cbiAgICAgICAgICByZXR1cm4gaW52b2tlKFwidGhyb3dcIiwgZXJyb3IsIHJlc29sdmUsIHJlamVjdCk7XG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH1cblxuICAgIHZhciBwcmV2aW91c1Byb21pc2U7XG5cbiAgICBmdW5jdGlvbiBlbnF1ZXVlKG1ldGhvZCwgYXJnKSB7XG4gICAgICBmdW5jdGlvbiBjYWxsSW52b2tlV2l0aE1ldGhvZEFuZEFyZygpIHtcbiAgICAgICAgcmV0dXJuIG5ldyBQcm9taXNlSW1wbChmdW5jdGlvbihyZXNvbHZlLCByZWplY3QpIHtcbiAgICAgICAgICBpbnZva2UobWV0aG9kLCBhcmcsIHJlc29sdmUsIHJlamVjdCk7XG4gICAgICAgIH0pO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gcHJldmlvdXNQcm9taXNlID1cbiAgICAgICAgLy8gSWYgZW5xdWV1ZSBoYXMgYmVlbiBjYWxsZWQgYmVmb3JlLCB0aGVuIHdlIHdhbnQgdG8gd2FpdCB1bnRpbFxuICAgICAgICAvLyBhbGwgcHJldmlvdXMgUHJvbWlzZXMgaGF2ZSBiZWVuIHJlc29sdmVkIGJlZm9yZSBjYWxsaW5nIGludm9rZSxcbiAgICAgICAgLy8gc28gdGhhdCByZXN1bHRzIGFyZSBhbHdheXMgZGVsaXZlcmVkIGluIHRoZSBjb3JyZWN0IG9yZGVyLiBJZlxuICAgICAgICAvLyBlbnF1ZXVlIGhhcyBub3QgYmVlbiBjYWxsZWQgYmVmb3JlLCB0aGVuIGl0IGlzIGltcG9ydGFudCB0b1xuICAgICAgICAvLyBjYWxsIGludm9rZSBpbW1lZGlhdGVseSwgd2l0aG91dCB3YWl0aW5nIG9uIGEgY2FsbGJhY2sgdG8gZmlyZSxcbiAgICAgICAgLy8gc28gdGhhdCB0aGUgYXN5bmMgZ2VuZXJhdG9yIGZ1bmN0aW9uIGhhcyB0aGUgb3Bwb3J0dW5pdHkgdG8gZG9cbiAgICAgICAgLy8gYW55IG5lY2Vzc2FyeSBzZXR1cCBpbiBhIHByZWRpY3RhYmxlIHdheS4gVGhpcyBwcmVkaWN0YWJpbGl0eVxuICAgICAgICAvLyBpcyB3aHkgdGhlIFByb21pc2UgY29uc3RydWN0b3Igc3luY2hyb25vdXNseSBpbnZva2VzIGl0c1xuICAgICAgICAvLyBleGVjdXRvciBjYWxsYmFjaywgYW5kIHdoeSBhc3luYyBmdW5jdGlvbnMgc3luY2hyb25vdXNseVxuICAgICAgICAvLyBleGVjdXRlIGNvZGUgYmVmb3JlIHRoZSBmaXJzdCBhd2FpdC4gU2luY2Ugd2UgaW1wbGVtZW50IHNpbXBsZVxuICAgICAgICAvLyBhc3luYyBmdW5jdGlvbnMgaW4gdGVybXMgb2YgYXN5bmMgZ2VuZXJhdG9ycywgaXQgaXMgZXNwZWNpYWxseVxuICAgICAgICAvLyBpbXBvcnRhbnQgdG8gZ2V0IHRoaXMgcmlnaHQsIGV2ZW4gdGhvdWdoIGl0IHJlcXVpcmVzIGNhcmUuXG4gICAgICAgIHByZXZpb3VzUHJvbWlzZSA/IHByZXZpb3VzUHJvbWlzZS50aGVuKFxuICAgICAgICAgIGNhbGxJbnZva2VXaXRoTWV0aG9kQW5kQXJnLFxuICAgICAgICAgIC8vIEF2b2lkIHByb3BhZ2F0aW5nIGZhaWx1cmVzIHRvIFByb21pc2VzIHJldHVybmVkIGJ5IGxhdGVyXG4gICAgICAgICAgLy8gaW52b2NhdGlvbnMgb2YgdGhlIGl0ZXJhdG9yLlxuICAgICAgICAgIGNhbGxJbnZva2VXaXRoTWV0aG9kQW5kQXJnXG4gICAgICAgICkgOiBjYWxsSW52b2tlV2l0aE1ldGhvZEFuZEFyZygpO1xuICAgIH1cblxuICAgIC8vIERlZmluZSB0aGUgdW5pZmllZCBoZWxwZXIgbWV0aG9kIHRoYXQgaXMgdXNlZCB0byBpbXBsZW1lbnQgLm5leHQsXG4gICAgLy8gLnRocm93LCBhbmQgLnJldHVybiAoc2VlIGRlZmluZUl0ZXJhdG9yTWV0aG9kcykuXG4gICAgdGhpcy5faW52b2tlID0gZW5xdWV1ZTtcbiAgfVxuXG4gIGRlZmluZUl0ZXJhdG9yTWV0aG9kcyhBc3luY0l0ZXJhdG9yLnByb3RvdHlwZSk7XG4gIEFzeW5jSXRlcmF0b3IucHJvdG90eXBlW2FzeW5jSXRlcmF0b3JTeW1ib2xdID0gZnVuY3Rpb24gKCkge1xuICAgIHJldHVybiB0aGlzO1xuICB9O1xuICBleHBvcnRzLkFzeW5jSXRlcmF0b3IgPSBBc3luY0l0ZXJhdG9yO1xuXG4gIC8vIE5vdGUgdGhhdCBzaW1wbGUgYXN5bmMgZnVuY3Rpb25zIGFyZSBpbXBsZW1lbnRlZCBvbiB0b3Agb2ZcbiAgLy8gQXN5bmNJdGVyYXRvciBvYmplY3RzOyB0aGV5IGp1c3QgcmV0dXJuIGEgUHJvbWlzZSBmb3IgdGhlIHZhbHVlIG9mXG4gIC8vIHRoZSBmaW5hbCByZXN1bHQgcHJvZHVjZWQgYnkgdGhlIGl0ZXJhdG9yLlxuICBleHBvcnRzLmFzeW5jID0gZnVuY3Rpb24oaW5uZXJGbiwgb3V0ZXJGbiwgc2VsZiwgdHJ5TG9jc0xpc3QsIFByb21pc2VJbXBsKSB7XG4gICAgaWYgKFByb21pc2VJbXBsID09PSB2b2lkIDApIFByb21pc2VJbXBsID0gUHJvbWlzZTtcblxuICAgIHZhciBpdGVyID0gbmV3IEFzeW5jSXRlcmF0b3IoXG4gICAgICB3cmFwKGlubmVyRm4sIG91dGVyRm4sIHNlbGYsIHRyeUxvY3NMaXN0KSxcbiAgICAgIFByb21pc2VJbXBsXG4gICAgKTtcblxuICAgIHJldHVybiBleHBvcnRzLmlzR2VuZXJhdG9yRnVuY3Rpb24ob3V0ZXJGbilcbiAgICAgID8gaXRlciAvLyBJZiBvdXRlckZuIGlzIGEgZ2VuZXJhdG9yLCByZXR1cm4gdGhlIGZ1bGwgaXRlcmF0b3IuXG4gICAgICA6IGl0ZXIubmV4dCgpLnRoZW4oZnVuY3Rpb24ocmVzdWx0KSB7XG4gICAgICAgICAgcmV0dXJuIHJlc3VsdC5kb25lID8gcmVzdWx0LnZhbHVlIDogaXRlci5uZXh0KCk7XG4gICAgICAgIH0pO1xuICB9O1xuXG4gIGZ1bmN0aW9uIG1ha2VJbnZva2VNZXRob2QoaW5uZXJGbiwgc2VsZiwgY29udGV4dCkge1xuICAgIHZhciBzdGF0ZSA9IEdlblN0YXRlU3VzcGVuZGVkU3RhcnQ7XG5cbiAgICByZXR1cm4gZnVuY3Rpb24gaW52b2tlKG1ldGhvZCwgYXJnKSB7XG4gICAgICBpZiAoc3RhdGUgPT09IEdlblN0YXRlRXhlY3V0aW5nKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihcIkdlbmVyYXRvciBpcyBhbHJlYWR5IHJ1bm5pbmdcIik7XG4gICAgICB9XG5cbiAgICAgIGlmIChzdGF0ZSA9PT0gR2VuU3RhdGVDb21wbGV0ZWQpIHtcbiAgICAgICAgaWYgKG1ldGhvZCA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgICAgdGhyb3cgYXJnO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gQmUgZm9yZ2l2aW5nLCBwZXIgMjUuMy4zLjMuMyBvZiB0aGUgc3BlYzpcbiAgICAgICAgLy8gaHR0cHM6Ly9wZW9wbGUubW96aWxsYS5vcmcvfmpvcmVuZG9yZmYvZXM2LWRyYWZ0Lmh0bWwjc2VjLWdlbmVyYXRvcnJlc3VtZVxuICAgICAgICByZXR1cm4gZG9uZVJlc3VsdCgpO1xuICAgICAgfVxuXG4gICAgICBjb250ZXh0Lm1ldGhvZCA9IG1ldGhvZDtcbiAgICAgIGNvbnRleHQuYXJnID0gYXJnO1xuXG4gICAgICB3aGlsZSAodHJ1ZSkge1xuICAgICAgICB2YXIgZGVsZWdhdGUgPSBjb250ZXh0LmRlbGVnYXRlO1xuICAgICAgICBpZiAoZGVsZWdhdGUpIHtcbiAgICAgICAgICB2YXIgZGVsZWdhdGVSZXN1bHQgPSBtYXliZUludm9rZURlbGVnYXRlKGRlbGVnYXRlLCBjb250ZXh0KTtcbiAgICAgICAgICBpZiAoZGVsZWdhdGVSZXN1bHQpIHtcbiAgICAgICAgICAgIGlmIChkZWxlZ2F0ZVJlc3VsdCA9PT0gQ29udGludWVTZW50aW5lbCkgY29udGludWU7XG4gICAgICAgICAgICByZXR1cm4gZGVsZWdhdGVSZXN1bHQ7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGNvbnRleHQubWV0aG9kID09PSBcIm5leHRcIikge1xuICAgICAgICAgIC8vIFNldHRpbmcgY29udGV4dC5fc2VudCBmb3IgbGVnYWN5IHN1cHBvcnQgb2YgQmFiZWwnc1xuICAgICAgICAgIC8vIGZ1bmN0aW9uLnNlbnQgaW1wbGVtZW50YXRpb24uXG4gICAgICAgICAgY29udGV4dC5zZW50ID0gY29udGV4dC5fc2VudCA9IGNvbnRleHQuYXJnO1xuXG4gICAgICAgIH0gZWxzZSBpZiAoY29udGV4dC5tZXRob2QgPT09IFwidGhyb3dcIikge1xuICAgICAgICAgIGlmIChzdGF0ZSA9PT0gR2VuU3RhdGVTdXNwZW5kZWRTdGFydCkge1xuICAgICAgICAgICAgc3RhdGUgPSBHZW5TdGF0ZUNvbXBsZXRlZDtcbiAgICAgICAgICAgIHRocm93IGNvbnRleHQuYXJnO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGNvbnRleHQuZGlzcGF0Y2hFeGNlcHRpb24oY29udGV4dC5hcmcpO1xuXG4gICAgICAgIH0gZWxzZSBpZiAoY29udGV4dC5tZXRob2QgPT09IFwicmV0dXJuXCIpIHtcbiAgICAgICAgICBjb250ZXh0LmFicnVwdChcInJldHVyblwiLCBjb250ZXh0LmFyZyk7XG4gICAgICAgIH1cblxuICAgICAgICBzdGF0ZSA9IEdlblN0YXRlRXhlY3V0aW5nO1xuXG4gICAgICAgIHZhciByZWNvcmQgPSB0cnlDYXRjaChpbm5lckZuLCBzZWxmLCBjb250ZXh0KTtcbiAgICAgICAgaWYgKHJlY29yZC50eXBlID09PSBcIm5vcm1hbFwiKSB7XG4gICAgICAgICAgLy8gSWYgYW4gZXhjZXB0aW9uIGlzIHRocm93biBmcm9tIGlubmVyRm4sIHdlIGxlYXZlIHN0YXRlID09PVxuICAgICAgICAgIC8vIEdlblN0YXRlRXhlY3V0aW5nIGFuZCBsb29wIGJhY2sgZm9yIGFub3RoZXIgaW52b2NhdGlvbi5cbiAgICAgICAgICBzdGF0ZSA9IGNvbnRleHQuZG9uZVxuICAgICAgICAgICAgPyBHZW5TdGF0ZUNvbXBsZXRlZFxuICAgICAgICAgICAgOiBHZW5TdGF0ZVN1c3BlbmRlZFlpZWxkO1xuXG4gICAgICAgICAgaWYgKHJlY29yZC5hcmcgPT09IENvbnRpbnVlU2VudGluZWwpIHtcbiAgICAgICAgICAgIGNvbnRpbnVlO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIHJldHVybiB7XG4gICAgICAgICAgICB2YWx1ZTogcmVjb3JkLmFyZyxcbiAgICAgICAgICAgIGRvbmU6IGNvbnRleHQuZG9uZVxuICAgICAgICAgIH07XG5cbiAgICAgICAgfSBlbHNlIGlmIChyZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgICAgc3RhdGUgPSBHZW5TdGF0ZUNvbXBsZXRlZDtcbiAgICAgICAgICAvLyBEaXNwYXRjaCB0aGUgZXhjZXB0aW9uIGJ5IGxvb3BpbmcgYmFjayBhcm91bmQgdG8gdGhlXG4gICAgICAgICAgLy8gY29udGV4dC5kaXNwYXRjaEV4Y2VwdGlvbihjb250ZXh0LmFyZykgY2FsbCBhYm92ZS5cbiAgICAgICAgICBjb250ZXh0Lm1ldGhvZCA9IFwidGhyb3dcIjtcbiAgICAgICAgICBjb250ZXh0LmFyZyA9IHJlY29yZC5hcmc7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9O1xuICB9XG5cbiAgLy8gQ2FsbCBkZWxlZ2F0ZS5pdGVyYXRvcltjb250ZXh0Lm1ldGhvZF0oY29udGV4dC5hcmcpIGFuZCBoYW5kbGUgdGhlXG4gIC8vIHJlc3VsdCwgZWl0aGVyIGJ5IHJldHVybmluZyBhIHsgdmFsdWUsIGRvbmUgfSByZXN1bHQgZnJvbSB0aGVcbiAgLy8gZGVsZWdhdGUgaXRlcmF0b3IsIG9yIGJ5IG1vZGlmeWluZyBjb250ZXh0Lm1ldGhvZCBhbmQgY29udGV4dC5hcmcsXG4gIC8vIHNldHRpbmcgY29udGV4dC5kZWxlZ2F0ZSB0byBudWxsLCBhbmQgcmV0dXJuaW5nIHRoZSBDb250aW51ZVNlbnRpbmVsLlxuICBmdW5jdGlvbiBtYXliZUludm9rZURlbGVnYXRlKGRlbGVnYXRlLCBjb250ZXh0KSB7XG4gICAgdmFyIG1ldGhvZCA9IGRlbGVnYXRlLml0ZXJhdG9yW2NvbnRleHQubWV0aG9kXTtcbiAgICBpZiAobWV0aG9kID09PSB1bmRlZmluZWQpIHtcbiAgICAgIC8vIEEgLnRocm93IG9yIC5yZXR1cm4gd2hlbiB0aGUgZGVsZWdhdGUgaXRlcmF0b3IgaGFzIG5vIC50aHJvd1xuICAgICAgLy8gbWV0aG9kIGFsd2F5cyB0ZXJtaW5hdGVzIHRoZSB5aWVsZCogbG9vcC5cbiAgICAgIGNvbnRleHQuZGVsZWdhdGUgPSBudWxsO1xuXG4gICAgICBpZiAoY29udGV4dC5tZXRob2QgPT09IFwidGhyb3dcIikge1xuICAgICAgICAvLyBOb3RlOiBbXCJyZXR1cm5cIl0gbXVzdCBiZSB1c2VkIGZvciBFUzMgcGFyc2luZyBjb21wYXRpYmlsaXR5LlxuICAgICAgICBpZiAoZGVsZWdhdGUuaXRlcmF0b3JbXCJyZXR1cm5cIl0pIHtcbiAgICAgICAgICAvLyBJZiB0aGUgZGVsZWdhdGUgaXRlcmF0b3IgaGFzIGEgcmV0dXJuIG1ldGhvZCwgZ2l2ZSBpdCBhXG4gICAgICAgICAgLy8gY2hhbmNlIHRvIGNsZWFuIHVwLlxuICAgICAgICAgIGNvbnRleHQubWV0aG9kID0gXCJyZXR1cm5cIjtcbiAgICAgICAgICBjb250ZXh0LmFyZyA9IHVuZGVmaW5lZDtcbiAgICAgICAgICBtYXliZUludm9rZURlbGVnYXRlKGRlbGVnYXRlLCBjb250ZXh0KTtcblxuICAgICAgICAgIGlmIChjb250ZXh0Lm1ldGhvZCA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgICAgICAvLyBJZiBtYXliZUludm9rZURlbGVnYXRlKGNvbnRleHQpIGNoYW5nZWQgY29udGV4dC5tZXRob2QgZnJvbVxuICAgICAgICAgICAgLy8gXCJyZXR1cm5cIiB0byBcInRocm93XCIsIGxldCB0aGF0IG92ZXJyaWRlIHRoZSBUeXBlRXJyb3IgYmVsb3cuXG4gICAgICAgICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBjb250ZXh0Lm1ldGhvZCA9IFwidGhyb3dcIjtcbiAgICAgICAgY29udGV4dC5hcmcgPSBuZXcgVHlwZUVycm9yKFxuICAgICAgICAgIFwiVGhlIGl0ZXJhdG9yIGRvZXMgbm90IHByb3ZpZGUgYSAndGhyb3cnIG1ldGhvZFwiKTtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgfVxuXG4gICAgdmFyIHJlY29yZCA9IHRyeUNhdGNoKG1ldGhvZCwgZGVsZWdhdGUuaXRlcmF0b3IsIGNvbnRleHQuYXJnKTtcblxuICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICBjb250ZXh0Lm1ldGhvZCA9IFwidGhyb3dcIjtcbiAgICAgIGNvbnRleHQuYXJnID0gcmVjb3JkLmFyZztcbiAgICAgIGNvbnRleHQuZGVsZWdhdGUgPSBudWxsO1xuICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgfVxuXG4gICAgdmFyIGluZm8gPSByZWNvcmQuYXJnO1xuXG4gICAgaWYgKCEgaW5mbykge1xuICAgICAgY29udGV4dC5tZXRob2QgPSBcInRocm93XCI7XG4gICAgICBjb250ZXh0LmFyZyA9IG5ldyBUeXBlRXJyb3IoXCJpdGVyYXRvciByZXN1bHQgaXMgbm90IGFuIG9iamVjdFwiKTtcbiAgICAgIGNvbnRleHQuZGVsZWdhdGUgPSBudWxsO1xuICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgfVxuXG4gICAgaWYgKGluZm8uZG9uZSkge1xuICAgICAgLy8gQXNzaWduIHRoZSByZXN1bHQgb2YgdGhlIGZpbmlzaGVkIGRlbGVnYXRlIHRvIHRoZSB0ZW1wb3JhcnlcbiAgICAgIC8vIHZhcmlhYmxlIHNwZWNpZmllZCBieSBkZWxlZ2F0ZS5yZXN1bHROYW1lIChzZWUgZGVsZWdhdGVZaWVsZCkuXG4gICAgICBjb250ZXh0W2RlbGVnYXRlLnJlc3VsdE5hbWVdID0gaW5mby52YWx1ZTtcblxuICAgICAgLy8gUmVzdW1lIGV4ZWN1dGlvbiBhdCB0aGUgZGVzaXJlZCBsb2NhdGlvbiAoc2VlIGRlbGVnYXRlWWllbGQpLlxuICAgICAgY29udGV4dC5uZXh0ID0gZGVsZWdhdGUubmV4dExvYztcblxuICAgICAgLy8gSWYgY29udGV4dC5tZXRob2Qgd2FzIFwidGhyb3dcIiBidXQgdGhlIGRlbGVnYXRlIGhhbmRsZWQgdGhlXG4gICAgICAvLyBleGNlcHRpb24sIGxldCB0aGUgb3V0ZXIgZ2VuZXJhdG9yIHByb2NlZWQgbm9ybWFsbHkuIElmXG4gICAgICAvLyBjb250ZXh0Lm1ldGhvZCB3YXMgXCJuZXh0XCIsIGZvcmdldCBjb250ZXh0LmFyZyBzaW5jZSBpdCBoYXMgYmVlblxuICAgICAgLy8gXCJjb25zdW1lZFwiIGJ5IHRoZSBkZWxlZ2F0ZSBpdGVyYXRvci4gSWYgY29udGV4dC5tZXRob2Qgd2FzXG4gICAgICAvLyBcInJldHVyblwiLCBhbGxvdyB0aGUgb3JpZ2luYWwgLnJldHVybiBjYWxsIHRvIGNvbnRpbnVlIGluIHRoZVxuICAgICAgLy8gb3V0ZXIgZ2VuZXJhdG9yLlxuICAgICAgaWYgKGNvbnRleHQubWV0aG9kICE9PSBcInJldHVyblwiKSB7XG4gICAgICAgIGNvbnRleHQubWV0aG9kID0gXCJuZXh0XCI7XG4gICAgICAgIGNvbnRleHQuYXJnID0gdW5kZWZpbmVkO1xuICAgICAgfVxuXG4gICAgfSBlbHNlIHtcbiAgICAgIC8vIFJlLXlpZWxkIHRoZSByZXN1bHQgcmV0dXJuZWQgYnkgdGhlIGRlbGVnYXRlIG1ldGhvZC5cbiAgICAgIHJldHVybiBpbmZvO1xuICAgIH1cblxuICAgIC8vIFRoZSBkZWxlZ2F0ZSBpdGVyYXRvciBpcyBmaW5pc2hlZCwgc28gZm9yZ2V0IGl0IGFuZCBjb250aW51ZSB3aXRoXG4gICAgLy8gdGhlIG91dGVyIGdlbmVyYXRvci5cbiAgICBjb250ZXh0LmRlbGVnYXRlID0gbnVsbDtcbiAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgfVxuXG4gIC8vIERlZmluZSBHZW5lcmF0b3IucHJvdG90eXBlLntuZXh0LHRocm93LHJldHVybn0gaW4gdGVybXMgb2YgdGhlXG4gIC8vIHVuaWZpZWQgLl9pbnZva2UgaGVscGVyIG1ldGhvZC5cbiAgZGVmaW5lSXRlcmF0b3JNZXRob2RzKEdwKTtcblxuICBkZWZpbmUoR3AsIHRvU3RyaW5nVGFnU3ltYm9sLCBcIkdlbmVyYXRvclwiKTtcblxuICAvLyBBIEdlbmVyYXRvciBzaG91bGQgYWx3YXlzIHJldHVybiBpdHNlbGYgYXMgdGhlIGl0ZXJhdG9yIG9iamVjdCB3aGVuIHRoZVxuICAvLyBAQGl0ZXJhdG9yIGZ1bmN0aW9uIGlzIGNhbGxlZCBvbiBpdC4gU29tZSBicm93c2VycycgaW1wbGVtZW50YXRpb25zIG9mIHRoZVxuICAvLyBpdGVyYXRvciBwcm90b3R5cGUgY2hhaW4gaW5jb3JyZWN0bHkgaW1wbGVtZW50IHRoaXMsIGNhdXNpbmcgdGhlIEdlbmVyYXRvclxuICAvLyBvYmplY3QgdG8gbm90IGJlIHJldHVybmVkIGZyb20gdGhpcyBjYWxsLiBUaGlzIGVuc3VyZXMgdGhhdCBkb2Vzbid0IGhhcHBlbi5cbiAgLy8gU2VlIGh0dHBzOi8vZ2l0aHViLmNvbS9mYWNlYm9vay9yZWdlbmVyYXRvci9pc3N1ZXMvMjc0IGZvciBtb3JlIGRldGFpbHMuXG4gIEdwW2l0ZXJhdG9yU3ltYm9sXSA9IGZ1bmN0aW9uKCkge1xuICAgIHJldHVybiB0aGlzO1xuICB9O1xuXG4gIEdwLnRvU3RyaW5nID0gZnVuY3Rpb24oKSB7XG4gICAgcmV0dXJuIFwiW29iamVjdCBHZW5lcmF0b3JdXCI7XG4gIH07XG5cbiAgZnVuY3Rpb24gcHVzaFRyeUVudHJ5KGxvY3MpIHtcbiAgICB2YXIgZW50cnkgPSB7IHRyeUxvYzogbG9jc1swXSB9O1xuXG4gICAgaWYgKDEgaW4gbG9jcykge1xuICAgICAgZW50cnkuY2F0Y2hMb2MgPSBsb2NzWzFdO1xuICAgIH1cblxuICAgIGlmICgyIGluIGxvY3MpIHtcbiAgICAgIGVudHJ5LmZpbmFsbHlMb2MgPSBsb2NzWzJdO1xuICAgICAgZW50cnkuYWZ0ZXJMb2MgPSBsb2NzWzNdO1xuICAgIH1cblxuICAgIHRoaXMudHJ5RW50cmllcy5wdXNoKGVudHJ5KTtcbiAgfVxuXG4gIGZ1bmN0aW9uIHJlc2V0VHJ5RW50cnkoZW50cnkpIHtcbiAgICB2YXIgcmVjb3JkID0gZW50cnkuY29tcGxldGlvbiB8fCB7fTtcbiAgICByZWNvcmQudHlwZSA9IFwibm9ybWFsXCI7XG4gICAgZGVsZXRlIHJlY29yZC5hcmc7XG4gICAgZW50cnkuY29tcGxldGlvbiA9IHJlY29yZDtcbiAgfVxuXG4gIGZ1bmN0aW9uIENvbnRleHQodHJ5TG9jc0xpc3QpIHtcbiAgICAvLyBUaGUgcm9vdCBlbnRyeSBvYmplY3QgKGVmZmVjdGl2ZWx5IGEgdHJ5IHN0YXRlbWVudCB3aXRob3V0IGEgY2F0Y2hcbiAgICAvLyBvciBhIGZpbmFsbHkgYmxvY2spIGdpdmVzIHVzIGEgcGxhY2UgdG8gc3RvcmUgdmFsdWVzIHRocm93biBmcm9tXG4gICAgLy8gbG9jYXRpb25zIHdoZXJlIHRoZXJlIGlzIG5vIGVuY2xvc2luZyB0cnkgc3RhdGVtZW50LlxuICAgIHRoaXMudHJ5RW50cmllcyA9IFt7IHRyeUxvYzogXCJyb290XCIgfV07XG4gICAgdHJ5TG9jc0xpc3QuZm9yRWFjaChwdXNoVHJ5RW50cnksIHRoaXMpO1xuICAgIHRoaXMucmVzZXQodHJ1ZSk7XG4gIH1cblxuICBleHBvcnRzLmtleXMgPSBmdW5jdGlvbihvYmplY3QpIHtcbiAgICB2YXIga2V5cyA9IFtdO1xuICAgIGZvciAodmFyIGtleSBpbiBvYmplY3QpIHtcbiAgICAgIGtleXMucHVzaChrZXkpO1xuICAgIH1cbiAgICBrZXlzLnJldmVyc2UoKTtcblxuICAgIC8vIFJhdGhlciB0aGFuIHJldHVybmluZyBhbiBvYmplY3Qgd2l0aCBhIG5leHQgbWV0aG9kLCB3ZSBrZWVwXG4gICAgLy8gdGhpbmdzIHNpbXBsZSBhbmQgcmV0dXJuIHRoZSBuZXh0IGZ1bmN0aW9uIGl0c2VsZi5cbiAgICByZXR1cm4gZnVuY3Rpb24gbmV4dCgpIHtcbiAgICAgIHdoaWxlIChrZXlzLmxlbmd0aCkge1xuICAgICAgICB2YXIga2V5ID0ga2V5cy5wb3AoKTtcbiAgICAgICAgaWYgKGtleSBpbiBvYmplY3QpIHtcbiAgICAgICAgICBuZXh0LnZhbHVlID0ga2V5O1xuICAgICAgICAgIG5leHQuZG9uZSA9IGZhbHNlO1xuICAgICAgICAgIHJldHVybiBuZXh0O1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIFRvIGF2b2lkIGNyZWF0aW5nIGFuIGFkZGl0aW9uYWwgb2JqZWN0LCB3ZSBqdXN0IGhhbmcgdGhlIC52YWx1ZVxuICAgICAgLy8gYW5kIC5kb25lIHByb3BlcnRpZXMgb2ZmIHRoZSBuZXh0IGZ1bmN0aW9uIG9iamVjdCBpdHNlbGYuIFRoaXNcbiAgICAgIC8vIGFsc28gZW5zdXJlcyB0aGF0IHRoZSBtaW5pZmllciB3aWxsIG5vdCBhbm9ueW1pemUgdGhlIGZ1bmN0aW9uLlxuICAgICAgbmV4dC5kb25lID0gdHJ1ZTtcbiAgICAgIHJldHVybiBuZXh0O1xuICAgIH07XG4gIH07XG5cbiAgZnVuY3Rpb24gdmFsdWVzKGl0ZXJhYmxlKSB7XG4gICAgaWYgKGl0ZXJhYmxlKSB7XG4gICAgICB2YXIgaXRlcmF0b3JNZXRob2QgPSBpdGVyYWJsZVtpdGVyYXRvclN5bWJvbF07XG4gICAgICBpZiAoaXRlcmF0b3JNZXRob2QpIHtcbiAgICAgICAgcmV0dXJuIGl0ZXJhdG9yTWV0aG9kLmNhbGwoaXRlcmFibGUpO1xuICAgICAgfVxuXG4gICAgICBpZiAodHlwZW9mIGl0ZXJhYmxlLm5leHQgPT09IFwiZnVuY3Rpb25cIikge1xuICAgICAgICByZXR1cm4gaXRlcmFibGU7XG4gICAgICB9XG5cbiAgICAgIGlmICghaXNOYU4oaXRlcmFibGUubGVuZ3RoKSkge1xuICAgICAgICB2YXIgaSA9IC0xLCBuZXh0ID0gZnVuY3Rpb24gbmV4dCgpIHtcbiAgICAgICAgICB3aGlsZSAoKytpIDwgaXRlcmFibGUubGVuZ3RoKSB7XG4gICAgICAgICAgICBpZiAoaGFzT3duLmNhbGwoaXRlcmFibGUsIGkpKSB7XG4gICAgICAgICAgICAgIG5leHQudmFsdWUgPSBpdGVyYWJsZVtpXTtcbiAgICAgICAgICAgICAgbmV4dC5kb25lID0gZmFsc2U7XG4gICAgICAgICAgICAgIHJldHVybiBuZXh0O1xuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cblxuICAgICAgICAgIG5leHQudmFsdWUgPSB1bmRlZmluZWQ7XG4gICAgICAgICAgbmV4dC5kb25lID0gdHJ1ZTtcblxuICAgICAgICAgIHJldHVybiBuZXh0O1xuICAgICAgICB9O1xuXG4gICAgICAgIHJldHVybiBuZXh0Lm5leHQgPSBuZXh0O1xuICAgICAgfVxuICAgIH1cblxuICAgIC8vIFJldHVybiBhbiBpdGVyYXRvciB3aXRoIG5vIHZhbHVlcy5cbiAgICByZXR1cm4geyBuZXh0OiBkb25lUmVzdWx0IH07XG4gIH1cbiAgZXhwb3J0cy52YWx1ZXMgPSB2YWx1ZXM7XG5cbiAgZnVuY3Rpb24gZG9uZVJlc3VsdCgpIHtcbiAgICByZXR1cm4geyB2YWx1ZTogdW5kZWZpbmVkLCBkb25lOiB0cnVlIH07XG4gIH1cblxuICBDb250ZXh0LnByb3RvdHlwZSA9IHtcbiAgICBjb25zdHJ1Y3RvcjogQ29udGV4dCxcblxuICAgIHJlc2V0OiBmdW5jdGlvbihza2lwVGVtcFJlc2V0KSB7XG4gICAgICB0aGlzLnByZXYgPSAwO1xuICAgICAgdGhpcy5uZXh0ID0gMDtcbiAgICAgIC8vIFJlc2V0dGluZyBjb250ZXh0Ll9zZW50IGZvciBsZWdhY3kgc3VwcG9ydCBvZiBCYWJlbCdzXG4gICAgICAvLyBmdW5jdGlvbi5zZW50IGltcGxlbWVudGF0aW9uLlxuICAgICAgdGhpcy5zZW50ID0gdGhpcy5fc2VudCA9IHVuZGVmaW5lZDtcbiAgICAgIHRoaXMuZG9uZSA9IGZhbHNlO1xuICAgICAgdGhpcy5kZWxlZ2F0ZSA9IG51bGw7XG5cbiAgICAgIHRoaXMubWV0aG9kID0gXCJuZXh0XCI7XG4gICAgICB0aGlzLmFyZyA9IHVuZGVmaW5lZDtcblxuICAgICAgdGhpcy50cnlFbnRyaWVzLmZvckVhY2gocmVzZXRUcnlFbnRyeSk7XG5cbiAgICAgIGlmICghc2tpcFRlbXBSZXNldCkge1xuICAgICAgICBmb3IgKHZhciBuYW1lIGluIHRoaXMpIHtcbiAgICAgICAgICAvLyBOb3Qgc3VyZSBhYm91dCB0aGUgb3B0aW1hbCBvcmRlciBvZiB0aGVzZSBjb25kaXRpb25zOlxuICAgICAgICAgIGlmIChuYW1lLmNoYXJBdCgwKSA9PT0gXCJ0XCIgJiZcbiAgICAgICAgICAgICAgaGFzT3duLmNhbGwodGhpcywgbmFtZSkgJiZcbiAgICAgICAgICAgICAgIWlzTmFOKCtuYW1lLnNsaWNlKDEpKSkge1xuICAgICAgICAgICAgdGhpc1tuYW1lXSA9IHVuZGVmaW5lZDtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9LFxuXG4gICAgc3RvcDogZnVuY3Rpb24oKSB7XG4gICAgICB0aGlzLmRvbmUgPSB0cnVlO1xuXG4gICAgICB2YXIgcm9vdEVudHJ5ID0gdGhpcy50cnlFbnRyaWVzWzBdO1xuICAgICAgdmFyIHJvb3RSZWNvcmQgPSByb290RW50cnkuY29tcGxldGlvbjtcbiAgICAgIGlmIChyb290UmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgICB0aHJvdyByb290UmVjb3JkLmFyZztcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIHRoaXMucnZhbDtcbiAgICB9LFxuXG4gICAgZGlzcGF0Y2hFeGNlcHRpb246IGZ1bmN0aW9uKGV4Y2VwdGlvbikge1xuICAgICAgaWYgKHRoaXMuZG9uZSkge1xuICAgICAgICB0aHJvdyBleGNlcHRpb247XG4gICAgICB9XG5cbiAgICAgIHZhciBjb250ZXh0ID0gdGhpcztcbiAgICAgIGZ1bmN0aW9uIGhhbmRsZShsb2MsIGNhdWdodCkge1xuICAgICAgICByZWNvcmQudHlwZSA9IFwidGhyb3dcIjtcbiAgICAgICAgcmVjb3JkLmFyZyA9IGV4Y2VwdGlvbjtcbiAgICAgICAgY29udGV4dC5uZXh0ID0gbG9jO1xuXG4gICAgICAgIGlmIChjYXVnaHQpIHtcbiAgICAgICAgICAvLyBJZiB0aGUgZGlzcGF0Y2hlZCBleGNlcHRpb24gd2FzIGNhdWdodCBieSBhIGNhdGNoIGJsb2NrLFxuICAgICAgICAgIC8vIHRoZW4gbGV0IHRoYXQgY2F0Y2ggYmxvY2sgaGFuZGxlIHRoZSBleGNlcHRpb24gbm9ybWFsbHkuXG4gICAgICAgICAgY29udGV4dC5tZXRob2QgPSBcIm5leHRcIjtcbiAgICAgICAgICBjb250ZXh0LmFyZyA9IHVuZGVmaW5lZDtcbiAgICAgICAgfVxuXG4gICAgICAgIHJldHVybiAhISBjYXVnaHQ7XG4gICAgICB9XG5cbiAgICAgIGZvciAodmFyIGkgPSB0aGlzLnRyeUVudHJpZXMubGVuZ3RoIC0gMTsgaSA+PSAwOyAtLWkpIHtcbiAgICAgICAgdmFyIGVudHJ5ID0gdGhpcy50cnlFbnRyaWVzW2ldO1xuICAgICAgICB2YXIgcmVjb3JkID0gZW50cnkuY29tcGxldGlvbjtcblxuICAgICAgICBpZiAoZW50cnkudHJ5TG9jID09PSBcInJvb3RcIikge1xuICAgICAgICAgIC8vIEV4Y2VwdGlvbiB0aHJvd24gb3V0c2lkZSBvZiBhbnkgdHJ5IGJsb2NrIHRoYXQgY291bGQgaGFuZGxlXG4gICAgICAgICAgLy8gaXQsIHNvIHNldCB0aGUgY29tcGxldGlvbiB2YWx1ZSBvZiB0aGUgZW50aXJlIGZ1bmN0aW9uIHRvXG4gICAgICAgICAgLy8gdGhyb3cgdGhlIGV4Y2VwdGlvbi5cbiAgICAgICAgICByZXR1cm4gaGFuZGxlKFwiZW5kXCIpO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKGVudHJ5LnRyeUxvYyA8PSB0aGlzLnByZXYpIHtcbiAgICAgICAgICB2YXIgaGFzQ2F0Y2ggPSBoYXNPd24uY2FsbChlbnRyeSwgXCJjYXRjaExvY1wiKTtcbiAgICAgICAgICB2YXIgaGFzRmluYWxseSA9IGhhc093bi5jYWxsKGVudHJ5LCBcImZpbmFsbHlMb2NcIik7XG5cbiAgICAgICAgICBpZiAoaGFzQ2F0Y2ggJiYgaGFzRmluYWxseSkge1xuICAgICAgICAgICAgaWYgKHRoaXMucHJldiA8IGVudHJ5LmNhdGNoTG9jKSB7XG4gICAgICAgICAgICAgIHJldHVybiBoYW5kbGUoZW50cnkuY2F0Y2hMb2MsIHRydWUpO1xuICAgICAgICAgICAgfSBlbHNlIGlmICh0aGlzLnByZXYgPCBlbnRyeS5maW5hbGx5TG9jKSB7XG4gICAgICAgICAgICAgIHJldHVybiBoYW5kbGUoZW50cnkuZmluYWxseUxvYyk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICB9IGVsc2UgaWYgKGhhc0NhdGNoKSB7XG4gICAgICAgICAgICBpZiAodGhpcy5wcmV2IDwgZW50cnkuY2F0Y2hMb2MpIHtcbiAgICAgICAgICAgICAgcmV0dXJuIGhhbmRsZShlbnRyeS5jYXRjaExvYywgdHJ1ZSk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICB9IGVsc2UgaWYgKGhhc0ZpbmFsbHkpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLnByZXYgPCBlbnRyeS5maW5hbGx5TG9jKSB7XG4gICAgICAgICAgICAgIHJldHVybiBoYW5kbGUoZW50cnkuZmluYWxseUxvYyk7XG4gICAgICAgICAgICB9XG5cbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwidHJ5IHN0YXRlbWVudCB3aXRob3V0IGNhdGNoIG9yIGZpbmFsbHlcIik7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfSxcblxuICAgIGFicnVwdDogZnVuY3Rpb24odHlwZSwgYXJnKSB7XG4gICAgICBmb3IgKHZhciBpID0gdGhpcy50cnlFbnRyaWVzLmxlbmd0aCAtIDE7IGkgPj0gMDsgLS1pKSB7XG4gICAgICAgIHZhciBlbnRyeSA9IHRoaXMudHJ5RW50cmllc1tpXTtcbiAgICAgICAgaWYgKGVudHJ5LnRyeUxvYyA8PSB0aGlzLnByZXYgJiZcbiAgICAgICAgICAgIGhhc093bi5jYWxsKGVudHJ5LCBcImZpbmFsbHlMb2NcIikgJiZcbiAgICAgICAgICAgIHRoaXMucHJldiA8IGVudHJ5LmZpbmFsbHlMb2MpIHtcbiAgICAgICAgICB2YXIgZmluYWxseUVudHJ5ID0gZW50cnk7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgaWYgKGZpbmFsbHlFbnRyeSAmJlxuICAgICAgICAgICh0eXBlID09PSBcImJyZWFrXCIgfHxcbiAgICAgICAgICAgdHlwZSA9PT0gXCJjb250aW51ZVwiKSAmJlxuICAgICAgICAgIGZpbmFsbHlFbnRyeS50cnlMb2MgPD0gYXJnICYmXG4gICAgICAgICAgYXJnIDw9IGZpbmFsbHlFbnRyeS5maW5hbGx5TG9jKSB7XG4gICAgICAgIC8vIElnbm9yZSB0aGUgZmluYWxseSBlbnRyeSBpZiBjb250cm9sIGlzIG5vdCBqdW1waW5nIHRvIGFcbiAgICAgICAgLy8gbG9jYXRpb24gb3V0c2lkZSB0aGUgdHJ5L2NhdGNoIGJsb2NrLlxuICAgICAgICBmaW5hbGx5RW50cnkgPSBudWxsO1xuICAgICAgfVxuXG4gICAgICB2YXIgcmVjb3JkID0gZmluYWxseUVudHJ5ID8gZmluYWxseUVudHJ5LmNvbXBsZXRpb24gOiB7fTtcbiAgICAgIHJlY29yZC50eXBlID0gdHlwZTtcbiAgICAgIHJlY29yZC5hcmcgPSBhcmc7XG5cbiAgICAgIGlmIChmaW5hbGx5RW50cnkpIHtcbiAgICAgICAgdGhpcy5tZXRob2QgPSBcIm5leHRcIjtcbiAgICAgICAgdGhpcy5uZXh0ID0gZmluYWxseUVudHJ5LmZpbmFsbHlMb2M7XG4gICAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gdGhpcy5jb21wbGV0ZShyZWNvcmQpO1xuICAgIH0sXG5cbiAgICBjb21wbGV0ZTogZnVuY3Rpb24ocmVjb3JkLCBhZnRlckxvYykge1xuICAgICAgaWYgKHJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgICAgdGhyb3cgcmVjb3JkLmFyZztcbiAgICAgIH1cblxuICAgICAgaWYgKHJlY29yZC50eXBlID09PSBcImJyZWFrXCIgfHxcbiAgICAgICAgICByZWNvcmQudHlwZSA9PT0gXCJjb250aW51ZVwiKSB7XG4gICAgICAgIHRoaXMubmV4dCA9IHJlY29yZC5hcmc7XG4gICAgICB9IGVsc2UgaWYgKHJlY29yZC50eXBlID09PSBcInJldHVyblwiKSB7XG4gICAgICAgIHRoaXMucnZhbCA9IHRoaXMuYXJnID0gcmVjb3JkLmFyZztcbiAgICAgICAgdGhpcy5tZXRob2QgPSBcInJldHVyblwiO1xuICAgICAgICB0aGlzLm5leHQgPSBcImVuZFwiO1xuICAgICAgfSBlbHNlIGlmIChyZWNvcmQudHlwZSA9PT0gXCJub3JtYWxcIiAmJiBhZnRlckxvYykge1xuICAgICAgICB0aGlzLm5leHQgPSBhZnRlckxvYztcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgfSxcblxuICAgIGZpbmlzaDogZnVuY3Rpb24oZmluYWxseUxvYykge1xuICAgICAgZm9yICh2YXIgaSA9IHRoaXMudHJ5RW50cmllcy5sZW5ndGggLSAxOyBpID49IDA7IC0taSkge1xuICAgICAgICB2YXIgZW50cnkgPSB0aGlzLnRyeUVudHJpZXNbaV07XG4gICAgICAgIGlmIChlbnRyeS5maW5hbGx5TG9jID09PSBmaW5hbGx5TG9jKSB7XG4gICAgICAgICAgdGhpcy5jb21wbGV0ZShlbnRyeS5jb21wbGV0aW9uLCBlbnRyeS5hZnRlckxvYyk7XG4gICAgICAgICAgcmVzZXRUcnlFbnRyeShlbnRyeSk7XG4gICAgICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9LFxuXG4gICAgXCJjYXRjaFwiOiBmdW5jdGlvbih0cnlMb2MpIHtcbiAgICAgIGZvciAodmFyIGkgPSB0aGlzLnRyeUVudHJpZXMubGVuZ3RoIC0gMTsgaSA+PSAwOyAtLWkpIHtcbiAgICAgICAgdmFyIGVudHJ5ID0gdGhpcy50cnlFbnRyaWVzW2ldO1xuICAgICAgICBpZiAoZW50cnkudHJ5TG9jID09PSB0cnlMb2MpIHtcbiAgICAgICAgICB2YXIgcmVjb3JkID0gZW50cnkuY29tcGxldGlvbjtcbiAgICAgICAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgICAgICAgdmFyIHRocm93biA9IHJlY29yZC5hcmc7XG4gICAgICAgICAgICByZXNldFRyeUVudHJ5KGVudHJ5KTtcbiAgICAgICAgICB9XG4gICAgICAgICAgcmV0dXJuIHRocm93bjtcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICAvLyBUaGUgY29udGV4dC5jYXRjaCBtZXRob2QgbXVzdCBvbmx5IGJlIGNhbGxlZCB3aXRoIGEgbG9jYXRpb25cbiAgICAgIC8vIGFyZ3VtZW50IHRoYXQgY29ycmVzcG9uZHMgdG8gYSBrbm93biBjYXRjaCBibG9jay5cbiAgICAgIHRocm93IG5ldyBFcnJvcihcImlsbGVnYWwgY2F0Y2ggYXR0ZW1wdFwiKTtcbiAgICB9LFxuXG4gICAgZGVsZWdhdGVZaWVsZDogZnVuY3Rpb24oaXRlcmFibGUsIHJlc3VsdE5hbWUsIG5leHRMb2MpIHtcbiAgICAgIHRoaXMuZGVsZWdhdGUgPSB7XG4gICAgICAgIGl0ZXJhdG9yOiB2YWx1ZXMoaXRlcmFibGUpLFxuICAgICAgICByZXN1bHROYW1lOiByZXN1bHROYW1lLFxuICAgICAgICBuZXh0TG9jOiBuZXh0TG9jXG4gICAgICB9O1xuXG4gICAgICBpZiAodGhpcy5tZXRob2QgPT09IFwibmV4dFwiKSB7XG4gICAgICAgIC8vIERlbGliZXJhdGVseSBmb3JnZXQgdGhlIGxhc3Qgc2VudCB2YWx1ZSBzbyB0aGF0IHdlIGRvbid0XG4gICAgICAgIC8vIGFjY2lkZW50YWxseSBwYXNzIGl0IG9uIHRvIHRoZSBkZWxlZ2F0ZS5cbiAgICAgICAgdGhpcy5hcmcgPSB1bmRlZmluZWQ7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgIH1cbiAgfTtcblxuICAvLyBSZWdhcmRsZXNzIG9mIHdoZXRoZXIgdGhpcyBzY3JpcHQgaXMgZXhlY3V0aW5nIGFzIGEgQ29tbW9uSlMgbW9kdWxlXG4gIC8vIG9yIG5vdCwgcmV0dXJuIHRoZSBydW50aW1lIG9iamVjdCBzbyB0aGF0IHdlIGNhbiBkZWNsYXJlIHRoZSB2YXJpYWJsZVxuICAvLyByZWdlbmVyYXRvclJ1bnRpbWUgaW4gdGhlIG91dGVyIHNjb3BlLCB3aGljaCBhbGxvd3MgdGhpcyBtb2R1bGUgdG8gYmVcbiAgLy8gaW5qZWN0ZWQgZWFzaWx5IGJ5IGBiaW4vcmVnZW5lcmF0b3IgLS1pbmNsdWRlLXJ1bnRpbWUgc2NyaXB0LmpzYC5cbiAgcmV0dXJuIGV4cG9ydHM7XG5cbn0oXG4gIC8vIElmIHRoaXMgc2NyaXB0IGlzIGV4ZWN1dGluZyBhcyBhIENvbW1vbkpTIG1vZHVsZSwgdXNlIG1vZHVsZS5leHBvcnRzXG4gIC8vIGFzIHRoZSByZWdlbmVyYXRvclJ1bnRpbWUgbmFtZXNwYWNlLiBPdGhlcndpc2UgY3JlYXRlIGEgbmV3IGVtcHR5XG4gIC8vIG9iamVjdC4gRWl0aGVyIHdheSwgdGhlIHJlc3VsdGluZyBvYmplY3Qgd2lsbCBiZSB1c2VkIHRvIGluaXRpYWxpemVcbiAgLy8gdGhlIHJlZ2VuZXJhdG9yUnVudGltZSB2YXJpYWJsZSBhdCB0aGUgdG9wIG9mIHRoaXMgZmlsZS5cbiAgdHlwZW9mIG1vZHVsZSA9PT0gXCJvYmplY3RcIiA/IG1vZHVsZS5leHBvcnRzIDoge31cbikpO1xuXG50cnkge1xuICByZWdlbmVyYXRvclJ1bnRpbWUgPSBydW50aW1lO1xufSBjYXRjaCAoYWNjaWRlbnRhbFN0cmljdE1vZGUpIHtcbiAgLy8gVGhpcyBtb2R1bGUgc2hvdWxkIG5vdCBiZSBydW5uaW5nIGluIHN0cmljdCBtb2RlLCBzbyB0aGUgYWJvdmVcbiAgLy8gYXNzaWdubWVudCBzaG91bGQgYWx3YXlzIHdvcmsgdW5sZXNzIHNvbWV0aGluZyBpcyBtaXNjb25maWd1cmVkLiBKdXN0XG4gIC8vIGluIGNhc2UgcnVudGltZS5qcyBhY2NpZGVudGFsbHkgcnVucyBpbiBzdHJpY3QgbW9kZSwgd2UgY2FuIGVzY2FwZVxuICAvLyBzdHJpY3QgbW9kZSB1c2luZyBhIGdsb2JhbCBGdW5jdGlvbiBjYWxsLiBUaGlzIGNvdWxkIGNvbmNlaXZhYmx5IGZhaWxcbiAgLy8gaWYgYSBDb250ZW50IFNlY3VyaXR5IFBvbGljeSBmb3JiaWRzIHVzaW5nIEZ1bmN0aW9uLCBidXQgaW4gdGhhdCBjYXNlXG4gIC8vIHRoZSBwcm9wZXIgc29sdXRpb24gaXMgdG8gZml4IHRoZSBhY2NpZGVudGFsIHN0cmljdCBtb2RlIHByb2JsZW0uIElmXG4gIC8vIHlvdSd2ZSBtaXNjb25maWd1cmVkIHlvdXIgYnVuZGxlciB0byBmb3JjZSBzdHJpY3QgbW9kZSBhbmQgYXBwbGllZCBhXG4gIC8vIENTUCB0byBmb3JiaWQgRnVuY3Rpb24sIGFuZCB5b3UncmUgbm90IHdpbGxpbmcgdG8gZml4IGVpdGhlciBvZiB0aG9zZVxuICAvLyBwcm9ibGVtcywgcGxlYXNlIGRldGFpbCB5b3VyIHVuaXF1ZSBwcmVkaWNhbWVudCBpbiBhIEdpdEh1YiBpc3N1ZS5cbiAgRnVuY3Rpb24oXCJyXCIsIFwicmVnZW5lcmF0b3JSdW50aW1lID0gclwiKShydW50aW1lKTtcbn1cbiIsIm1vZHVsZS5leHBvcnRzID0gcmVxdWlyZShcInJlZ2VuZXJhdG9yLXJ1bnRpbWVcIik7XG4iLCJpbXBvcnQgc2ltcGxlR2l0IGZyb20gJ3NpbXBsZS1naXQnXG5cbmltcG9ydCB7IHJlYWRDaGFuZ2Vsb2csIHJlcXVpcmVFbnYsIHNhdmVDaGFuZ2Vsb2cgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcblxuY29uc3QgZmluYWxpemVDdXJyZW50RW50cnkgPSBhc3luYyhjaGFuZ2Vsb2cpID0+IHtcbiAgY29uc3QgY3VycmVudEVudHJ5ID0gY2hhbmdlbG9nWzBdXG5cbiAgLy8gdXBkYXRlIHRoZSBpbnZvbHZlZCBwcm9qZWN0c1xuICBjb25zdCBpbnZvbHZlZFByb2plY3RzID0gcmVxdWlyZUVudignSU5WT0xWRURfUFJPSkVDVFMnKS5zcGxpdCgnXFxuJylcbiAgY3VycmVudEVudHJ5Lmludm9sdmVkUHJvamVjdHMgPSBpbnZvbHZlZFByb2plY3RzXG5cbiAgY29uc3QgYnJhbmNoRnJvbSA9IGN1cnJlbnRFbnRyeS5icmFuY2hGcm9tXG4gIGNvbnN0IGdpdE9wdGlvbnMgPSB7XG4gICAgYmFzZURpciAgICAgICAgICAgICAgICA6IHByb2Nlc3MuY3dkKCksXG4gICAgYmluYXJ5ICAgICAgICAgICAgICAgICA6ICdnaXQnLFxuICAgIG1heENvbmN1cnJlbnRQcm9jZXNzZXMgOiA2XG4gIH1cbiAgY29uc3QgZ2l0ID0gc2ltcGxlR2l0KGdpdE9wdGlvbnMpXG4gIGNvbnN0IHJlc3VsdHMgPSBhd2FpdCBnaXQucmF3KCdzaG9ydGxvZycsICctLXN1bW1hcnknLCAnLS1lbWFpbCcsIGAke2JyYW5jaEZyb219Li4uSEVBRGApXG4gIGNvbnN0IGNvbnRyaWJ1dG9ycyA9IHJlc3VsdHNcbiAgICAuc3BsaXQoJ1xcbicpXG4gICAgLm1hcCgobCkgPT4gbC5yZXBsYWNlKC9eW1xcc1xcZF0rXFxzKy8sICcnKSlcbiAgICAuZmlsdGVyKChsKSA9PiBsLmxlbmd0aCA+IDApXG4gIGN1cnJlbnRFbnRyeS5jb250cmlidXRvcnMgPSBjb250cmlidXRvcnNcblxuICAvKlxuICBcInFhXCI6IHtcbiAgICAgXCJ0ZXN0ZWRWZXJzaW9uXCI6IFwiYmY4MjBlMzE4Li4uXCIsXG4gICAgIFwidW5pdFRlc3RSZXBvcnRcIjogXCJodHRwczovLy4uLlwiLFxuICAgICBcImxpbnRSZXBvcnRcIjogXCJodHRwczovLy4uLlwiXG4gIH1cbiAgKi9cbiAgcmV0dXJuIGN1cnJlbnRFbnRyeVxufVxuXG5jb25zdCBmaW5hbGl6ZUNoYW5nZWxvZyA9IGFzeW5jKCkgPT4ge1xuICBjb25zdCBjaGFuZ2Vsb2cgPSByZWFkQ2hhbmdlbG9nKClcbiAgYXdhaXQgZmluYWxpemVDdXJyZW50RW50cnkoY2hhbmdlbG9nKVxuICBzYXZlQ2hhbmdlbG9nKGNoYW5nZWxvZylcbn1cblxuZXhwb3J0IHsgZmluYWxpemVDdXJyZW50RW50cnksIGZpbmFsaXplQ2hhbmdlbG9nIH1cbiIsImltcG9ydCAqIGFzIGZzIGZyb20gJ2ZzJ1xuaW1wb3J0IFlBTUwgZnJvbSAneWFtbCdcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZywgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBwcmludEVudHJpZXMgPSAoaG90Zml4ZXMsIGxhc3RSZWxlYXNlRGF0ZSkgPT4ge1xuICBjb25zdCBjaGFuZ2Vsb2cgPSByZWFkQ2hhbmdlbG9nKClcblxuICAvLyBUT0RPOiB0aGlzIGlzIGEgYml0IG9mIGEgbGltaXRhdGlvbiByZXF1aXJpbmcgdGhlIHNjcmlwdCBwd2QgdG8gYmUgdGhlIHBhY2thZ2Ugcm9vdC5cbiAgY29uc3QgcGFja2FnZUNvbnRlbnRzID0gZnMucmVhZEZpbGVTeW5jKCdwYWNrYWdlLmpzb24nKVxuICBjb25zdCBwYWNrYWdlRGF0YSA9IEpTT04ucGFyc2UocGFja2FnZUNvbnRlbnRzKVxuXG4gIGNvbnN0IGNoYW5nZUVudHJpZXMgPSBjaGFuZ2Vsb2cubWFwKHIgPT4gKHsgdGltZTogbmV3IERhdGUoci5zdGFydFRpbWVzdGFtcCksIG5vdGVzOiByLmNoYW5nZU5vdGVzLCBhdXRob3I6ci53b3JrSW5pdGlhdG9yIH0pKVxuICAgIC5jb25jYXQoaG90Zml4ZXMubWFwKHIgPT4gKFxuICAgICAge1xuICAgICAgICB0aW1lOiBuZXcgRGF0ZShyLmRhdGUpLFxuICAgICAgICBub3RlczogW3IubWVzc2FnZS5yZXBsYWNlKC9eXFxzKmhvdGZpeFxccyo6P1xccyovaSwgJycpXSxcbiAgICAgICAgYXV0aG9yOiByLmF1dGhvci5lbWFpbCxcbiAgICAgICAgaXNIb3RmaXg6IHRydWUgfVxuICApKSlcbiAgLmZpbHRlcihyID0+IHIudGltZSA+PSBsYXN0UmVsZWFzZURhdGUpXG4gIGNoYW5nZUVudHJpZXMuc29ydCgoYSwgYikgPT4gYS50aW1lIDwgYi50aW1lID8gLTEgOiBhLnRpbWUgPT0gYi50aW1lID8gMCA6IDEpXG5cbiAgbGV0IHNlY3VyaXR5Tm90ZXMgPSBbXVxuICBsZXQgZHJwQmNwTm90ZXMgPSBbXVxuICBsZXQgYmFja291dE5vdGVzID0gW11cblxuICBmb3IgKGNvbnN0IGVudHJ5IG9mIGNoYW5nZWxvZykge1xuICAgIGlmIChlbnRyeS5zZWN1cml0eU5vdGVzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgIHNlY3VyaXR5Tm90ZXMgPSBzZWN1cml0eU5vdGVzLmNvbmNhdChlbnRyeS5zZWN1cml0eU5vdGVzKVxuICAgIH1cbiAgICBpZiAoZW50cnkuZHJwQmNwTm90ZXMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgZHJwQmNwTm90ZXMgPSBkcnBCY3BOb3Rlcy5jb25jYXQoZW50cnkuZHJwQmNwTm90ZXMpXG4gICAgfVxuICAgIGlmIChlbnRyeS5iYWNrb3V0Tm90ZXMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgYmFja291dE5vdGVzID0gYmFja291dE5vdGVzLmNvbmNhdChlbnRyeS5iYWNrb3V0Tm90ZXMpXG4gICAgfVxuICB9XG5cbiAgY29uc3QgYXR0cmliID0gKGVudHJ5KSA9PiBgXygke2VudHJ5LmF1dGhvcn07ICR7ZW50cnkudGltZS50b0lTT1N0cmluZygpfSlfYFxuXG4gIGZvciAoY29uc3QgZW50cnkgb2YgY2hhbmdlRW50cmllcykge1xuICAgIGlmIChlbnRyeS5pc0hvdGZpeCkge1xuICAgICAgY29uc29sZS5sb2coYCogXyoqaG90Zml4KipfOiAke2VudHJ5Lm5vdGVzWzBdfSAke2F0dHJpYihlbnRyeSl9YClcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICBmb3IgKGNvbnN0IG5vdGUgb2YgZW50cnkubm90ZXMpIHtcbiAgICAgICAgY29uc29sZS5sb2coYCogJHtub3RlfSAke2F0dHJpYihlbnRyeSl9YClcbiAgICAgIH1cbiAgICB9XG4gIH1cbiAgaWYgKHBhY2thZ2VEYXRhPy5saXE/LmNvbnRyYWN0cz8uc2VjdXJlIHx8IHNlY3VyaXR5Tm90ZXMubGVuZ3RoID4gMCkge1xuICAgIGNvbnNvbGUubG9nKFwiXFxuIyMjIFNlY3VyaXR5IG5vdGVzXFxuXFxuXCIpXG4gICAgY29uc29sZS5sb2coYCR7c2VjdXJpdHlOb3Rlcy5sZW5ndGggPT09IDAgPyAnX25vbmVfJyA6IGAqICR7c2VjdXJpdHlOb3Rlcy5qb2luKFwiXFxuKiBcIil9YH1gKVxuICB9XG4gIGlmICgvKiBUT0RPOiBhbiBvcmcgc2V0dGluZyBvcmcuc2V0dGluZ3M/LlsnbWFpbnRhaW5zIERSUC9CQ1AnXSB8fCovIGRycEJjcE5vdGVzLmxlbmd0aCA+IDApIHtcbiAgICBjb25zb2xlLmxvZyhcIlxcbiMjIyBEUlAvQkNQIG5vdGVzXFxuXFxuXCIpXG4gICAgY29uc29sZS5sb2coYCR7ZHJwQmNwTm90ZXMubGVuZ3RoID09PSAwID8gJ19ub25lXycgOiBgKiAke2RycEJjcE5vdGVzLmpvaW4oXCJcXG4qIFwiKX1gfWApXG4gIH1cbiAgaWYgKHBhY2thZ2VEYXRhPy5saXE/LmNvbnRyYWN0cz8uWydoaWdoIGF2YWlsYWJpbGl0eSddIHx8IGJhY2tvdXROb3Rlcy5sZW5ndGggPiAwKSB7XG4gICAgY29uc29sZS5sb2coXCJcXG4jIyMgQmFja291dCBub3Rlc1xcblxcblwiKVxuICAgIGNvbnNvbGUubG9nKGAke2JhY2tvdXROb3Rlcy5sZW5ndGggPT09IDAgPyAnX25vbmVfJyA6IGAqICR7YmFja291dE5vdGVzLmpvaW4oXCJcXG4qIFwiKX1gfWApXG4gIH1cbn1cblxuZXhwb3J0IHsgcHJpbnRFbnRyaWVzIH1cbiIsImZ1bmN0aW9uIF9hcnJheVdpdGhIb2xlcyhhcnIpIHtcbiAgaWYgKEFycmF5LmlzQXJyYXkoYXJyKSkgcmV0dXJuIGFycjtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfYXJyYXlXaXRoSG9sZXM7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiZnVuY3Rpb24gX2l0ZXJhYmxlVG9BcnJheUxpbWl0KGFyciwgaSkge1xuICB2YXIgX2kgPSBhcnIgPT0gbnVsbCA/IG51bGwgOiB0eXBlb2YgU3ltYm9sICE9PSBcInVuZGVmaW5lZFwiICYmIGFycltTeW1ib2wuaXRlcmF0b3JdIHx8IGFycltcIkBAaXRlcmF0b3JcIl07XG5cbiAgaWYgKF9pID09IG51bGwpIHJldHVybjtcbiAgdmFyIF9hcnIgPSBbXTtcbiAgdmFyIF9uID0gdHJ1ZTtcbiAgdmFyIF9kID0gZmFsc2U7XG5cbiAgdmFyIF9zLCBfZTtcblxuICB0cnkge1xuICAgIGZvciAoX2kgPSBfaS5jYWxsKGFycik7ICEoX24gPSAoX3MgPSBfaS5uZXh0KCkpLmRvbmUpOyBfbiA9IHRydWUpIHtcbiAgICAgIF9hcnIucHVzaChfcy52YWx1ZSk7XG5cbiAgICAgIGlmIChpICYmIF9hcnIubGVuZ3RoID09PSBpKSBicmVhaztcbiAgICB9XG4gIH0gY2F0Y2ggKGVycikge1xuICAgIF9kID0gdHJ1ZTtcbiAgICBfZSA9IGVycjtcbiAgfSBmaW5hbGx5IHtcbiAgICB0cnkge1xuICAgICAgaWYgKCFfbiAmJiBfaVtcInJldHVyblwiXSAhPSBudWxsKSBfaVtcInJldHVyblwiXSgpO1xuICAgIH0gZmluYWxseSB7XG4gICAgICBpZiAoX2QpIHRocm93IF9lO1xuICAgIH1cbiAgfVxuXG4gIHJldHVybiBfYXJyO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9pdGVyYWJsZVRvQXJyYXlMaW1pdDtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCJmdW5jdGlvbiBfYXJyYXlMaWtlVG9BcnJheShhcnIsIGxlbikge1xuICBpZiAobGVuID09IG51bGwgfHwgbGVuID4gYXJyLmxlbmd0aCkgbGVuID0gYXJyLmxlbmd0aDtcblxuICBmb3IgKHZhciBpID0gMCwgYXJyMiA9IG5ldyBBcnJheShsZW4pOyBpIDwgbGVuOyBpKyspIHtcbiAgICBhcnIyW2ldID0gYXJyW2ldO1xuICB9XG5cbiAgcmV0dXJuIGFycjI7XG59XG5cbm1vZHVsZS5leHBvcnRzID0gX2FycmF5TGlrZVRvQXJyYXk7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwidmFyIGFycmF5TGlrZVRvQXJyYXkgPSByZXF1aXJlKFwiLi9hcnJheUxpa2VUb0FycmF5LmpzXCIpO1xuXG5mdW5jdGlvbiBfdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkobywgbWluTGVuKSB7XG4gIGlmICghbykgcmV0dXJuO1xuICBpZiAodHlwZW9mIG8gPT09IFwic3RyaW5nXCIpIHJldHVybiBhcnJheUxpa2VUb0FycmF5KG8sIG1pbkxlbik7XG4gIHZhciBuID0gT2JqZWN0LnByb3RvdHlwZS50b1N0cmluZy5jYWxsKG8pLnNsaWNlKDgsIC0xKTtcbiAgaWYgKG4gPT09IFwiT2JqZWN0XCIgJiYgby5jb25zdHJ1Y3RvcikgbiA9IG8uY29uc3RydWN0b3IubmFtZTtcbiAgaWYgKG4gPT09IFwiTWFwXCIgfHwgbiA9PT0gXCJTZXRcIikgcmV0dXJuIEFycmF5LmZyb20obyk7XG4gIGlmIChuID09PSBcIkFyZ3VtZW50c1wiIHx8IC9eKD86VWl8SSludCg/Ojh8MTZ8MzIpKD86Q2xhbXBlZCk/QXJyYXkkLy50ZXN0KG4pKSByZXR1cm4gYXJyYXlMaWtlVG9BcnJheShvLCBtaW5MZW4pO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheTtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCJmdW5jdGlvbiBfbm9uSXRlcmFibGVSZXN0KCkge1xuICB0aHJvdyBuZXcgVHlwZUVycm9yKFwiSW52YWxpZCBhdHRlbXB0IHRvIGRlc3RydWN0dXJlIG5vbi1pdGVyYWJsZSBpbnN0YW5jZS5cXG5JbiBvcmRlciB0byBiZSBpdGVyYWJsZSwgbm9uLWFycmF5IG9iamVjdHMgbXVzdCBoYXZlIGEgW1N5bWJvbC5pdGVyYXRvcl0oKSBtZXRob2QuXCIpO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9ub25JdGVyYWJsZVJlc3Q7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwidmFyIGFycmF5V2l0aEhvbGVzID0gcmVxdWlyZShcIi4vYXJyYXlXaXRoSG9sZXMuanNcIik7XG5cbnZhciBpdGVyYWJsZVRvQXJyYXlMaW1pdCA9IHJlcXVpcmUoXCIuL2l0ZXJhYmxlVG9BcnJheUxpbWl0LmpzXCIpO1xuXG52YXIgdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkgPSByZXF1aXJlKFwiLi91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheS5qc1wiKTtcblxudmFyIG5vbkl0ZXJhYmxlUmVzdCA9IHJlcXVpcmUoXCIuL25vbkl0ZXJhYmxlUmVzdC5qc1wiKTtcblxuZnVuY3Rpb24gX3NsaWNlZFRvQXJyYXkoYXJyLCBpKSB7XG4gIHJldHVybiBhcnJheVdpdGhIb2xlcyhhcnIpIHx8IGl0ZXJhYmxlVG9BcnJheUxpbWl0KGFyciwgaSkgfHwgdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkoYXJyLCBpKSB8fCBub25JdGVyYWJsZVJlc3QoKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfc2xpY2VkVG9BcnJheTtcbm1vZHVsZS5leHBvcnRzW1wiZGVmYXVsdFwiXSA9IG1vZHVsZS5leHBvcnRzLCBtb2R1bGUuZXhwb3J0cy5fX2VzTW9kdWxlID0gdHJ1ZTsiLCIvLyBUT0RPOiBvbmNlIHdlJ3ZlIHVwZGF0ZWQgYWxsIG91ciBvbGQgJ2NoYW5nZWxvZy5qc29uJyBmb3JtYXRzLCB3ZSBjYW4gZHJvcCB0aGlzLiBUaGVyZSBhcmUgbm8gZXhhbXBsZXMgJ2luIHRoZSB3aWxkJyB0aGF0IHdlIG5lZWQgdG8gd29ycnkgYWJvdXQuXG5cbmltcG9ydCAqIGFzIGZzIGZyb20gJ2ZzJ1xuaW1wb3J0IHsgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCByZWFkT2xkQ2hhbmdlbG9nID0gKCkgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG4gIGNvbnN0IG9sZENsUGF0aCA9IGAke2NsUGF0aC5zdWJzdHJpbmcoMCwgY2xQYXRoLmxlbmd0aCAtIDUpfS5qc29uYFxuXG4gIGNvbnN0IG9sZENsQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMob2xkQ2xQYXRoKVxuICBjb25zdCBvbGRDbCA9IEpTT04ucGFyc2Uob2xkQ2xDb250ZW50cylcblxuICByZXR1cm4gb2xkQ2xcbn1cblxuY29uc3QgY29udmVydEZvcm1hdCA9IChjaGFuZ2Vsb2cpID0+IHtcbiAgY2hhbmdlbG9nLnJldmVyc2UoKSAvLyBpbi1wbGFjZSBtb2RpZmljYXRpb25cbiAgZm9yIChjb25zdCBlbnRyeSBvZiBjaGFuZ2Vsb2cpIHtcbiAgICBjb25zdCBuZXdTdGFydCA9IG5ldyBEYXRlKClcbiAgICBuZXdTdGFydC5zZXRUaW1lKDApXG4gICAgLy8gb2xkIGZvcm1hdDogVVRDOnl5eXktbW0tZGQtSEhNTSBaXG4gICAgY29uc3QgWyB5ZWFyLCBtb250aCwgZGF0ZSwgdGltZSBdID0gZW50cnkuc3RhcnRUaW1lc3RhbXBMb2NhbC5zcGxpdCgnICcpWzBdLnNwbGl0KCctJylcbiAgICBjb25zdCBob3VyID0gdGltZS5zdWJzdHJpbmcoMCwgMSlcbiAgICBjb25zdCBtaW51dGVzID0gdGltZS5zdWJzdHJpbmcoMilcblxuICAgIG5ld1N0YXJ0LnNldFVUQ0Z1bGxZZWFyKHllYXIpXG4gICAgbmV3U3RhcnQuc2V0VVRDTW9udGgobW9udGggLSAxKVxuICAgIG5ld1N0YXJ0LnNldFVUQ0RhdGUoZGF0ZSlcbiAgICBuZXdTdGFydC5zZXRVVENIb3Vycyhob3VyKVxuICAgIG5ld1N0YXJ0LnNldFVUQ01pbnV0ZXMobWludXRlcylcblxuICAgIGVudHJ5LnN0YXJ0VGltZXN0YW1wID0gbmV3U3RhcnQudG9JU09TdHJpbmcoKVxuICAgIGRlbGV0ZSBlbnRyeS5zdGFydFRpbWVzdGFtcExvY2FsXG5cbiAgICBlbnRyeS5zdGFydEVwb2NoTWlsbGlzID0gbmV3U3RhcnQuZ2V0VGltZSgpXG5cbiAgICBlbnRyeS5jaGFuZ2VOb3RlcyA9IFsgZW50cnkuZGVzY3JpcHRpb24gXVxuICAgIGRlbGV0ZSBlbnRyeS5kZXNjcmlwdGlvblxuXG4gICAgZW50cnkuc2VjdXJpdHlOb3RlcyA9IFtdXG4gICAgZW50cnkuZHJwQmNwTm90ZXMgPSBbXVxuICAgIGVudHJ5LmJhY2tvdXROb3RlcyA9IFtdXG4gIH1cblxuICByZXR1cm4gY2hhbmdlbG9nXG59XG5cbmNvbnN0IHVwZGF0ZUZpbGVGb3JtYXQgPSAoKSA9PiB7XG4gIGNvbnN0IG9sZENsID0gcmVhZE9sZENoYW5nZWxvZygpXG4gIGNvbnN0IGNoYW5nZWxvZyA9IGNvbnZlcnRGb3JtYXQob2xkQ2wpXG4gIHNhdmVDaGFuZ2Vsb2coY2hhbmdlbG9nKVxufVxuXG5leHBvcnQgeyBjb252ZXJ0Rm9ybWF0LCB1cGRhdGVGaWxlRm9ybWF0IH1cbiIsImltcG9ydCB7IGFkZEVudHJ5IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnknXG5pbXBvcnQgeyBmaW5hbGl6ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1hY3Rpb24tZmluYWxpemUtZW50cnknXG5pbXBvcnQgeyBwcmludEVudHJpZXMgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctYWN0aW9uLXByaW50LWVudHJpZXMnXG5pbXBvcnQgeyB1cGRhdGVGaWxlRm9ybWF0IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi11cGRhdGUtZm9ybWF0J1xuXG4vLyBTZXR1cCB2YWxpZCBhY3Rpb25zXG5jb25zdCBBRERfRU5UUlkgPSAnYWRkLWVudHJ5J1xuY29uc3QgRklOQUxJWkVfRU5UUlkgPSAnZmluYWxpemUtZW50cnknXG5jb25zdCBQUklOVF9FTlRSSUVTID0gJ3ByaW50LWVudHJpZXMnXG5jb25zdCBVUERBVEVfRk9STUFUPSAndXBkYXRlLWZvcm1hdCdcbmNvbnN0IHZhbGlkQWN0aW9ucyA9IFtBRERfRU5UUlksIEZJTkFMSVpFX0VOVFJZLCBQUklOVF9FTlRSSUVTLCBVUERBVEVfRk9STUFUXVxuXG5jb25zdCBkZXRlcm1pbmVBY3Rpb24gPSAoKSA9PiB7XG4gIGNvbnN0IGFyZ3MgPSBwcm9jZXNzLmFyZ3Yuc2xpY2UoMilcblxuICBpZiAoYXJncy5sZW5ndGggPT09IDApIHsgLy8gfHwgYXJncy5sZW5ndGggPiAxKSB7IFRPRE86IHdlIGRvIG5lZWQgYXJncyBmb3IgJ3ByaW50LWNoYW5nZWxvZycuLi5cbiAgICB0aHJvdyBuZXcgRXJyb3IoJ1VuZXhwZWN0ZWQgYXJndW1lbnQgY291bnQuIFBsZWFzZSBwcm92aWRlIGV4YWN0bHkgb25lIGFjdGlvbiBhcmd1bWVudC4nKVxuICB9XG5cbiAgY29uc3QgYWN0aW9uID0gYXJnc1swXVxuICBpZiAodmFsaWRBY3Rpb25zLmluZGV4T2YoYWN0aW9uKSA9PT0gLTEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYEludmFsaWQgYWN0aW9uOiAke2FjdGlvbn1gKVxuICB9XG5cbiAgc3dpdGNoIChhY3Rpb24pIHtcbiAgY2FzZSBBRERfRU5UUlk6XG4gICAgcmV0dXJuIGFkZEVudHJ5XG4gIGNhc2UgRklOQUxJWkVfRU5UUlk6XG4gICAgcmV0dXJuIGZpbmFsaXplQ2hhbmdlbG9nXG4gIGNhc2UgUFJJTlRfRU5UUklFUzpcbiAgICByZXR1cm4gKCkgPT4gcHJpbnRFbnRyaWVzKEpTT04ucGFyc2UoYXJnc1sxXSksIG5ldyBEYXRlKGFyZ3NbMl0pKVxuICBjYXNlIFVQREFURV9GT1JNQVQ6XG4gICAgcmV0dXJuIHVwZGF0ZUZpbGVGb3JtYXRcbiAgZGVmYXVsdDpcbiAgICB0aHJvdyBuZXcgRXJyb3IoYENhbm5vdCBwcm9jZXNzIHVua293biBhY3Rpb246ICR7YWN0aW9ufWApXG4gIH1cbn1cblxuY29uc3QgZXhlY3V0ZSA9ICgpID0+IHtcbiAgZGV0ZXJtaW5lQWN0aW9uKCkuY2FsbCgpXG59XG5cbmV4cG9ydCB7XG4gIGRldGVybWluZUFjdGlvbixcbiAgZXhlY3V0ZSxcbiAgdmFsaWRBY3Rpb25zXG59XG4iLCJpbXBvcnQgeyBleGVjdXRlIH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLXJ1bm5lcidcblxuZXhlY3V0ZSgpXG4iXSwibmFtZXMiOlsicmVhZENoYW5nZWxvZyIsImNsUGF0aGlzaCIsInJlcXVpcmVFbnYiLCJjbFBhdGgiLCJjaGFuZ2Vsb2dDb250ZW50cyIsImZzIiwicmVhZEZpbGVTeW5jIiwiY2hhbmdlbG9nIiwiWUFNTCIsInBhcnNlIiwia2V5IiwicHJvY2VzcyIsImVudiIsIkVycm9yIiwic2F2ZUNoYW5nZWxvZyIsInN0cmluZ2lmeSIsIndyaXRlRmlsZVN5bmMiLCJjcmVhdGVOZXdFbnRyeSIsIm5vdyIsIkRhdGUiLCJzdGFydFRpbWVzdGFtcCIsImRhdGVGb3JtYXQiLCJzdGFydEVwb2NoTWlsbGlzIiwiaXNzdWVzIiwic3BsaXQiLCJpbnZvbHZlZFByb2plY3RzIiwibmV3RW50cnkiLCJicmFuY2giLCJicmFuY2hGcm9tIiwid29ya0luaXRpYXRvciIsImJyYW5jaEluaXRpYXRvciIsImNoYW5nZU5vdGVzIiwic2VjdXJpdHlOb3RlcyIsImRycEJjcE5vdGVzIiwiYmFja291dE5vdGVzIiwicHVzaCIsImFkZEVudHJ5IiwidW5kZWZpbmVkIiwicmVxdWlyZSQkMCIsImZpbmFsaXplQ3VycmVudEVudHJ5IiwiY3VycmVudEVudHJ5IiwiZ2l0T3B0aW9ucyIsImJhc2VEaXIiLCJjd2QiLCJiaW5hcnkiLCJtYXhDb25jdXJyZW50UHJvY2Vzc2VzIiwiZ2l0Iiwic2ltcGxlR2l0IiwicmF3IiwicmVzdWx0cyIsImNvbnRyaWJ1dG9ycyIsIm1hcCIsImwiLCJyZXBsYWNlIiwiZmlsdGVyIiwibGVuZ3RoIiwiZmluYWxpemVDaGFuZ2Vsb2ciLCJwcmludEVudHJpZXMiLCJob3RmaXhlcyIsImxhc3RSZWxlYXNlRGF0ZSIsInBhY2thZ2VDb250ZW50cyIsInBhY2thZ2VEYXRhIiwiSlNPTiIsImNoYW5nZUVudHJpZXMiLCJyIiwidGltZSIsIm5vdGVzIiwiYXV0aG9yIiwiY29uY2F0IiwiZGF0ZSIsIm1lc3NhZ2UiLCJlbWFpbCIsImlzSG90Zml4Iiwic29ydCIsImEiLCJiIiwiZW50cnkiLCJhdHRyaWIiLCJ0b0lTT1N0cmluZyIsImNvbnNvbGUiLCJsb2ciLCJub3RlIiwibGlxIiwiY29udHJhY3RzIiwic2VjdXJlIiwiam9pbiIsInJlYWRPbGRDaGFuZ2Vsb2ciLCJvbGRDbFBhdGgiLCJzdWJzdHJpbmciLCJvbGRDbENvbnRlbnRzIiwib2xkQ2wiLCJjb252ZXJ0Rm9ybWF0IiwicmV2ZXJzZSIsIm5ld1N0YXJ0Iiwic2V0VGltZSIsInN0YXJ0VGltZXN0YW1wTG9jYWwiLCJ5ZWFyIiwibW9udGgiLCJob3VyIiwibWludXRlcyIsInNldFVUQ0Z1bGxZZWFyIiwic2V0VVRDTW9udGgiLCJzZXRVVENEYXRlIiwic2V0VVRDSG91cnMiLCJzZXRVVENNaW51dGVzIiwiZ2V0VGltZSIsImRlc2NyaXB0aW9uIiwidXBkYXRlRmlsZUZvcm1hdCIsIkFERF9FTlRSWSIsIkZJTkFMSVpFX0VOVFJZIiwiUFJJTlRfRU5UUklFUyIsIlVQREFURV9GT1JNQVQiLCJ2YWxpZEFjdGlvbnMiLCJkZXRlcm1pbmVBY3Rpb24iLCJhcmdzIiwiYXJndiIsInNsaWNlIiwiYWN0aW9u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
