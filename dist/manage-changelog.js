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
  var startEpochMillis = now.getTime(); // process the 'work unit' data

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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFuYWdlLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvY2hhbmdlbG9nL2xpYi1jaGFuZ2Vsb2ctY29yZS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9hc3luY1RvR2VuZXJhdG9yLmpzIiwiLi4vbm9kZV9tb2R1bGVzL3JlZ2VuZXJhdG9yLXJ1bnRpbWUvcnVudGltZS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9yZWdlbmVyYXRvci9pbmRleC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1maW5hbGl6ZS1lbnRyeS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1wcmludC1lbnRyaWVzLmpzIiwiLi4vbm9kZV9tb2R1bGVzL0BiYWJlbC9ydW50aW1lL2hlbHBlcnMvYXJyYXlXaXRoSG9sZXMuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy9pdGVyYWJsZVRvQXJyYXlMaW1pdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL2FycmF5TGlrZVRvQXJyYXkuanMiLCIuLi9ub2RlX21vZHVsZXMvQGJhYmVsL3J1bnRpbWUvaGVscGVycy91bnN1cHBvcnRlZEl0ZXJhYmxlVG9BcnJheS5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL25vbkl0ZXJhYmxlUmVzdC5qcyIsIi4uL25vZGVfbW9kdWxlcy9AYmFiZWwvcnVudGltZS9oZWxwZXJzL3NsaWNlZFRvQXJyYXkuanMiLCIuLi9zcmMvbGlxL2FjdGlvbnMvd29yay9jaGFuZ2Vsb2cvbGliLWNoYW5nZWxvZy1hY3Rpb24tdXBkYXRlLWZvcm1hdC5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLXJ1bm5lci5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9pbmRleC5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcbmltcG9ydCBZQU1MIGZyb20gJ3lhbWwnXG5cbmNvbnN0IHJlYWRDaGFuZ2Vsb2cgPSAoKSA9PiB7XG4gIGNvbnN0IGNsUGF0aGlzaCA9IHJlcXVpcmVFbnYoJ0NIQU5HRUxPR19GSUxFJylcbiAgY29uc3QgY2xQYXRoID0gY2xQYXRoaXNoID09PSAnLScgPyAwIDogY2xQYXRoaXNoXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoY2xQYXRoLCAndXRmOCcpIC8vIGluY2x1ZGUgZW5jb2RpbmcgdG8gZ2V0ICdzdHJpbmcnIHJlc3VsdFxuICBjb25zdCBjaGFuZ2Vsb2cgPSBZQU1MLnBhcnNlKGNoYW5nZWxvZ0NvbnRlbnRzKVxuXG4gIHJldHVybiBjaGFuZ2Vsb2dcbn1cblxuY29uc3QgcmVxdWlyZUVudiA9IChrZXkpID0+IHtcbiAgcmV0dXJuIHByb2Nlc3MuZW52W2tleV0gfHwgdGhyb3cgbmV3IEVycm9yKGBEaWQgbm90IGZpbmQgcmVxdWlyZWQgZW52aXJvbm1lbnQgcGFyYW1ldGVyOiAke2tleX1gKVxufVxuXG5jb25zdCBzYXZlQ2hhbmdlbG9nID0gKGNoYW5nZWxvZykgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBZQU1MLnN0cmluZ2lmeShjaGFuZ2Vsb2cpXG4gIGZzLndyaXRlRmlsZVN5bmMoY2xQYXRoLCBjaGFuZ2Vsb2dDb250ZW50cylcbn1cblxuZXhwb3J0IHtcbiAgcmVhZENoYW5nZWxvZyxcbiAgcmVxdWlyZUVudixcbiAgc2F2ZUNoYW5nZWxvZ1xufVxuIiwiaW1wb3J0IGRhdGVGb3JtYXQgZnJvbSAnZGF0ZWZvcm1hdCdcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZywgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBjcmVhdGVOZXdFbnRyeSA9IChjaGFuZ2Vsb2cpID0+IHtcbiAgLy8gZ2V0IHRoZSBhcHByb3ggc3RhcnQgdGltZSBhY2NvcmRpbmcgdG8gdGhlIGxvY2FsIGNsb2NrXG4gIGNvbnN0IG5vdyA9IG5ldyBEYXRlKClcbiAgY29uc3Qgc3RhcnRUaW1lc3RhbXAgPSBkYXRlRm9ybWF0KG5vdywgJ1VUQzp5eXl5LW1tLWRkLUhITU0uc3MgWicpXG4gIGNvbnN0IHN0YXJ0RXBvY2hNaWxsaXMgPSBub3cuZ2V0VGltZSgpXG4gIC8vIHByb2Nlc3MgdGhlICd3b3JrIHVuaXQnIGRhdGFcbiAgY29uc3QgaXNzdWVzID0gcmVxdWlyZUVudignV09SS19JU1NVRVMnKS5zcGxpdCgnXFxuJylcbiAgY29uc3QgaW52b2x2ZWRQcm9qZWN0cyA9IHJlcXVpcmVFbnYoJ0lOVk9MVkVEX1BST0pFQ1RTJykuc3BsaXQoJ1xcbicpXG5cbiAgY29uc3QgbmV3RW50cnkgPSB7XG4gICAgc3RhcnRUaW1lc3RhbXAsXG4gICAgc3RhcnRFcG9jaE1pbGxpcyxcbiAgICBpc3N1ZXMsXG4gICAgYnJhbmNoICAgICAgICAgIDogcmVxdWlyZUVudignV09SS19CUkFOQ0gnKSxcbiAgICBicmFuY2hGcm9tICAgICAgOiByZXF1aXJlRW52KCdDVVJSX1JFUE9fVkVSU0lPTicpLFxuICAgIHdvcmtJbml0aWF0b3IgICA6IHJlcXVpcmVFbnYoJ1dPUktfSU5JVElBVE9SJyksXG4gICAgYnJhbmNoSW5pdGlhdG9yIDogcmVxdWlyZUVudignQ1VSUl9VU0VSJyksXG4gICAgaW52b2x2ZWRQcm9qZWN0cyxcbiAgICBjaGFuZ2VOb3RlcyAgICAgOiBbcmVxdWlyZUVudignV09SS19ERVNDJyldLFxuICAgIHNlY3VyaXR5Tm90ZXMgICA6IFtdLFxuICAgIGRycEJjcE5vdGVzICAgICA6IFtdLFxuICAgIGJhY2tvdXROb3RlcyAgICA6IFtdXG4gIH1cblxuICBjaGFuZ2Vsb2cucHVzaChuZXdFbnRyeSlcbiAgcmV0dXJuIG5ld0VudHJ5XG59XG5cbmNvbnN0IGFkZEVudHJ5ID0gKCkgPT4ge1xuICBjb25zdCBjaGFuZ2Vsb2cgPSByZWFkQ2hhbmdlbG9nKClcbiAgY3JlYXRlTmV3RW50cnkoY2hhbmdlbG9nKVxuICBzYXZlQ2hhbmdlbG9nKGNoYW5nZWxvZylcbn1cblxuZXhwb3J0IHsgYWRkRW50cnksIGNyZWF0ZU5ld0VudHJ5IH1cbiIsImZ1bmN0aW9uIGFzeW5jR2VuZXJhdG9yU3RlcChnZW4sIHJlc29sdmUsIHJlamVjdCwgX25leHQsIF90aHJvdywga2V5LCBhcmcpIHtcbiAgdHJ5IHtcbiAgICB2YXIgaW5mbyA9IGdlbltrZXldKGFyZyk7XG4gICAgdmFyIHZhbHVlID0gaW5mby52YWx1ZTtcbiAgfSBjYXRjaCAoZXJyb3IpIHtcbiAgICByZWplY3QoZXJyb3IpO1xuICAgIHJldHVybjtcbiAgfVxuXG4gIGlmIChpbmZvLmRvbmUpIHtcbiAgICByZXNvbHZlKHZhbHVlKTtcbiAgfSBlbHNlIHtcbiAgICBQcm9taXNlLnJlc29sdmUodmFsdWUpLnRoZW4oX25leHQsIF90aHJvdyk7XG4gIH1cbn1cblxuZnVuY3Rpb24gX2FzeW5jVG9HZW5lcmF0b3IoZm4pIHtcbiAgcmV0dXJuIGZ1bmN0aW9uICgpIHtcbiAgICB2YXIgc2VsZiA9IHRoaXMsXG4gICAgICAgIGFyZ3MgPSBhcmd1bWVudHM7XG4gICAgcmV0dXJuIG5ldyBQcm9taXNlKGZ1bmN0aW9uIChyZXNvbHZlLCByZWplY3QpIHtcbiAgICAgIHZhciBnZW4gPSBmbi5hcHBseShzZWxmLCBhcmdzKTtcblxuICAgICAgZnVuY3Rpb24gX25leHQodmFsdWUpIHtcbiAgICAgICAgYXN5bmNHZW5lcmF0b3JTdGVwKGdlbiwgcmVzb2x2ZSwgcmVqZWN0LCBfbmV4dCwgX3Rocm93LCBcIm5leHRcIiwgdmFsdWUpO1xuICAgICAgfVxuXG4gICAgICBmdW5jdGlvbiBfdGhyb3coZXJyKSB7XG4gICAgICAgIGFzeW5jR2VuZXJhdG9yU3RlcChnZW4sIHJlc29sdmUsIHJlamVjdCwgX25leHQsIF90aHJvdywgXCJ0aHJvd1wiLCBlcnIpO1xuICAgICAgfVxuXG4gICAgICBfbmV4dCh1bmRlZmluZWQpO1xuICAgIH0pO1xuICB9O1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9hc3luY1RvR2VuZXJhdG9yO1xubW9kdWxlLmV4cG9ydHNbXCJkZWZhdWx0XCJdID0gbW9kdWxlLmV4cG9ydHMsIG1vZHVsZS5leHBvcnRzLl9fZXNNb2R1bGUgPSB0cnVlOyIsIi8qKlxuICogQ29weXJpZ2h0IChjKSAyMDE0LXByZXNlbnQsIEZhY2Vib29rLCBJbmMuXG4gKlxuICogVGhpcyBzb3VyY2UgY29kZSBpcyBsaWNlbnNlZCB1bmRlciB0aGUgTUlUIGxpY2Vuc2UgZm91bmQgaW4gdGhlXG4gKiBMSUNFTlNFIGZpbGUgaW4gdGhlIHJvb3QgZGlyZWN0b3J5IG9mIHRoaXMgc291cmNlIHRyZWUuXG4gKi9cblxudmFyIHJ1bnRpbWUgPSAoZnVuY3Rpb24gKGV4cG9ydHMpIHtcbiAgXCJ1c2Ugc3RyaWN0XCI7XG5cbiAgdmFyIE9wID0gT2JqZWN0LnByb3RvdHlwZTtcbiAgdmFyIGhhc093biA9IE9wLmhhc093blByb3BlcnR5O1xuICB2YXIgdW5kZWZpbmVkOyAvLyBNb3JlIGNvbXByZXNzaWJsZSB0aGFuIHZvaWQgMC5cbiAgdmFyICRTeW1ib2wgPSB0eXBlb2YgU3ltYm9sID09PSBcImZ1bmN0aW9uXCIgPyBTeW1ib2wgOiB7fTtcbiAgdmFyIGl0ZXJhdG9yU3ltYm9sID0gJFN5bWJvbC5pdGVyYXRvciB8fCBcIkBAaXRlcmF0b3JcIjtcbiAgdmFyIGFzeW5jSXRlcmF0b3JTeW1ib2wgPSAkU3ltYm9sLmFzeW5jSXRlcmF0b3IgfHwgXCJAQGFzeW5jSXRlcmF0b3JcIjtcbiAgdmFyIHRvU3RyaW5nVGFnU3ltYm9sID0gJFN5bWJvbC50b1N0cmluZ1RhZyB8fCBcIkBAdG9TdHJpbmdUYWdcIjtcblxuICBmdW5jdGlvbiBkZWZpbmUob2JqLCBrZXksIHZhbHVlKSB7XG4gICAgT2JqZWN0LmRlZmluZVByb3BlcnR5KG9iaiwga2V5LCB7XG4gICAgICB2YWx1ZTogdmFsdWUsXG4gICAgICBlbnVtZXJhYmxlOiB0cnVlLFxuICAgICAgY29uZmlndXJhYmxlOiB0cnVlLFxuICAgICAgd3JpdGFibGU6IHRydWVcbiAgICB9KTtcbiAgICByZXR1cm4gb2JqW2tleV07XG4gIH1cbiAgdHJ5IHtcbiAgICAvLyBJRSA4IGhhcyBhIGJyb2tlbiBPYmplY3QuZGVmaW5lUHJvcGVydHkgdGhhdCBvbmx5IHdvcmtzIG9uIERPTSBvYmplY3RzLlxuICAgIGRlZmluZSh7fSwgXCJcIik7XG4gIH0gY2F0Y2ggKGVycikge1xuICAgIGRlZmluZSA9IGZ1bmN0aW9uKG9iaiwga2V5LCB2YWx1ZSkge1xuICAgICAgcmV0dXJuIG9ialtrZXldID0gdmFsdWU7XG4gICAgfTtcbiAgfVxuXG4gIGZ1bmN0aW9uIHdyYXAoaW5uZXJGbiwgb3V0ZXJGbiwgc2VsZiwgdHJ5TG9jc0xpc3QpIHtcbiAgICAvLyBJZiBvdXRlckZuIHByb3ZpZGVkIGFuZCBvdXRlckZuLnByb3RvdHlwZSBpcyBhIEdlbmVyYXRvciwgdGhlbiBvdXRlckZuLnByb3RvdHlwZSBpbnN0YW5jZW9mIEdlbmVyYXRvci5cbiAgICB2YXIgcHJvdG9HZW5lcmF0b3IgPSBvdXRlckZuICYmIG91dGVyRm4ucHJvdG90eXBlIGluc3RhbmNlb2YgR2VuZXJhdG9yID8gb3V0ZXJGbiA6IEdlbmVyYXRvcjtcbiAgICB2YXIgZ2VuZXJhdG9yID0gT2JqZWN0LmNyZWF0ZShwcm90b0dlbmVyYXRvci5wcm90b3R5cGUpO1xuICAgIHZhciBjb250ZXh0ID0gbmV3IENvbnRleHQodHJ5TG9jc0xpc3QgfHwgW10pO1xuXG4gICAgLy8gVGhlIC5faW52b2tlIG1ldGhvZCB1bmlmaWVzIHRoZSBpbXBsZW1lbnRhdGlvbnMgb2YgdGhlIC5uZXh0LFxuICAgIC8vIC50aHJvdywgYW5kIC5yZXR1cm4gbWV0aG9kcy5cbiAgICBnZW5lcmF0b3IuX2ludm9rZSA9IG1ha2VJbnZva2VNZXRob2QoaW5uZXJGbiwgc2VsZiwgY29udGV4dCk7XG5cbiAgICByZXR1cm4gZ2VuZXJhdG9yO1xuICB9XG4gIGV4cG9ydHMud3JhcCA9IHdyYXA7XG5cbiAgLy8gVHJ5L2NhdGNoIGhlbHBlciB0byBtaW5pbWl6ZSBkZW9wdGltaXphdGlvbnMuIFJldHVybnMgYSBjb21wbGV0aW9uXG4gIC8vIHJlY29yZCBsaWtlIGNvbnRleHQudHJ5RW50cmllc1tpXS5jb21wbGV0aW9uLiBUaGlzIGludGVyZmFjZSBjb3VsZFxuICAvLyBoYXZlIGJlZW4gKGFuZCB3YXMgcHJldmlvdXNseSkgZGVzaWduZWQgdG8gdGFrZSBhIGNsb3N1cmUgdG8gYmVcbiAgLy8gaW52b2tlZCB3aXRob3V0IGFyZ3VtZW50cywgYnV0IGluIGFsbCB0aGUgY2FzZXMgd2UgY2FyZSBhYm91dCB3ZVxuICAvLyBhbHJlYWR5IGhhdmUgYW4gZXhpc3RpbmcgbWV0aG9kIHdlIHdhbnQgdG8gY2FsbCwgc28gdGhlcmUncyBubyBuZWVkXG4gIC8vIHRvIGNyZWF0ZSBhIG5ldyBmdW5jdGlvbiBvYmplY3QuIFdlIGNhbiBldmVuIGdldCBhd2F5IHdpdGggYXNzdW1pbmdcbiAgLy8gdGhlIG1ldGhvZCB0YWtlcyBleGFjdGx5IG9uZSBhcmd1bWVudCwgc2luY2UgdGhhdCBoYXBwZW5zIHRvIGJlIHRydWVcbiAgLy8gaW4gZXZlcnkgY2FzZSwgc28gd2UgZG9uJ3QgaGF2ZSB0byB0b3VjaCB0aGUgYXJndW1lbnRzIG9iamVjdC4gVGhlXG4gIC8vIG9ubHkgYWRkaXRpb25hbCBhbGxvY2F0aW9uIHJlcXVpcmVkIGlzIHRoZSBjb21wbGV0aW9uIHJlY29yZCwgd2hpY2hcbiAgLy8gaGFzIGEgc3RhYmxlIHNoYXBlIGFuZCBzbyBob3BlZnVsbHkgc2hvdWxkIGJlIGNoZWFwIHRvIGFsbG9jYXRlLlxuICBmdW5jdGlvbiB0cnlDYXRjaChmbiwgb2JqLCBhcmcpIHtcbiAgICB0cnkge1xuICAgICAgcmV0dXJuIHsgdHlwZTogXCJub3JtYWxcIiwgYXJnOiBmbi5jYWxsKG9iaiwgYXJnKSB9O1xuICAgIH0gY2F0Y2ggKGVycikge1xuICAgICAgcmV0dXJuIHsgdHlwZTogXCJ0aHJvd1wiLCBhcmc6IGVyciB9O1xuICAgIH1cbiAgfVxuXG4gIHZhciBHZW5TdGF0ZVN1c3BlbmRlZFN0YXJ0ID0gXCJzdXNwZW5kZWRTdGFydFwiO1xuICB2YXIgR2VuU3RhdGVTdXNwZW5kZWRZaWVsZCA9IFwic3VzcGVuZGVkWWllbGRcIjtcbiAgdmFyIEdlblN0YXRlRXhlY3V0aW5nID0gXCJleGVjdXRpbmdcIjtcbiAgdmFyIEdlblN0YXRlQ29tcGxldGVkID0gXCJjb21wbGV0ZWRcIjtcblxuICAvLyBSZXR1cm5pbmcgdGhpcyBvYmplY3QgZnJvbSB0aGUgaW5uZXJGbiBoYXMgdGhlIHNhbWUgZWZmZWN0IGFzXG4gIC8vIGJyZWFraW5nIG91dCBvZiB0aGUgZGlzcGF0Y2ggc3dpdGNoIHN0YXRlbWVudC5cbiAgdmFyIENvbnRpbnVlU2VudGluZWwgPSB7fTtcblxuICAvLyBEdW1teSBjb25zdHJ1Y3RvciBmdW5jdGlvbnMgdGhhdCB3ZSB1c2UgYXMgdGhlIC5jb25zdHJ1Y3RvciBhbmRcbiAgLy8gLmNvbnN0cnVjdG9yLnByb3RvdHlwZSBwcm9wZXJ0aWVzIGZvciBmdW5jdGlvbnMgdGhhdCByZXR1cm4gR2VuZXJhdG9yXG4gIC8vIG9iamVjdHMuIEZvciBmdWxsIHNwZWMgY29tcGxpYW5jZSwgeW91IG1heSB3aXNoIHRvIGNvbmZpZ3VyZSB5b3VyXG4gIC8vIG1pbmlmaWVyIG5vdCB0byBtYW5nbGUgdGhlIG5hbWVzIG9mIHRoZXNlIHR3byBmdW5jdGlvbnMuXG4gIGZ1bmN0aW9uIEdlbmVyYXRvcigpIHt9XG4gIGZ1bmN0aW9uIEdlbmVyYXRvckZ1bmN0aW9uKCkge31cbiAgZnVuY3Rpb24gR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGUoKSB7fVxuXG4gIC8vIFRoaXMgaXMgYSBwb2x5ZmlsbCBmb3IgJUl0ZXJhdG9yUHJvdG90eXBlJSBmb3IgZW52aXJvbm1lbnRzIHRoYXRcbiAgLy8gZG9uJ3QgbmF0aXZlbHkgc3VwcG9ydCBpdC5cbiAgdmFyIEl0ZXJhdG9yUHJvdG90eXBlID0ge307XG4gIEl0ZXJhdG9yUHJvdG90eXBlW2l0ZXJhdG9yU3ltYm9sXSA9IGZ1bmN0aW9uICgpIHtcbiAgICByZXR1cm4gdGhpcztcbiAgfTtcblxuICB2YXIgZ2V0UHJvdG8gPSBPYmplY3QuZ2V0UHJvdG90eXBlT2Y7XG4gIHZhciBOYXRpdmVJdGVyYXRvclByb3RvdHlwZSA9IGdldFByb3RvICYmIGdldFByb3RvKGdldFByb3RvKHZhbHVlcyhbXSkpKTtcbiAgaWYgKE5hdGl2ZUl0ZXJhdG9yUHJvdG90eXBlICYmXG4gICAgICBOYXRpdmVJdGVyYXRvclByb3RvdHlwZSAhPT0gT3AgJiZcbiAgICAgIGhhc093bi5jYWxsKE5hdGl2ZUl0ZXJhdG9yUHJvdG90eXBlLCBpdGVyYXRvclN5bWJvbCkpIHtcbiAgICAvLyBUaGlzIGVudmlyb25tZW50IGhhcyBhIG5hdGl2ZSAlSXRlcmF0b3JQcm90b3R5cGUlOyB1c2UgaXQgaW5zdGVhZFxuICAgIC8vIG9mIHRoZSBwb2x5ZmlsbC5cbiAgICBJdGVyYXRvclByb3RvdHlwZSA9IE5hdGl2ZUl0ZXJhdG9yUHJvdG90eXBlO1xuICB9XG5cbiAgdmFyIEdwID0gR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGUucHJvdG90eXBlID1cbiAgICBHZW5lcmF0b3IucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShJdGVyYXRvclByb3RvdHlwZSk7XG4gIEdlbmVyYXRvckZ1bmN0aW9uLnByb3RvdHlwZSA9IEdwLmNvbnN0cnVjdG9yID0gR2VuZXJhdG9yRnVuY3Rpb25Qcm90b3R5cGU7XG4gIEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlLmNvbnN0cnVjdG9yID0gR2VuZXJhdG9yRnVuY3Rpb247XG4gIEdlbmVyYXRvckZ1bmN0aW9uLmRpc3BsYXlOYW1lID0gZGVmaW5lKFxuICAgIEdlbmVyYXRvckZ1bmN0aW9uUHJvdG90eXBlLFxuICAgIHRvU3RyaW5nVGFnU3ltYm9sLFxuICAgIFwiR2VuZXJhdG9yRnVuY3Rpb25cIlxuICApO1xuXG4gIC8vIEhlbHBlciBmb3IgZGVmaW5pbmcgdGhlIC5uZXh0LCAudGhyb3csIGFuZCAucmV0dXJuIG1ldGhvZHMgb2YgdGhlXG4gIC8vIEl0ZXJhdG9yIGludGVyZmFjZSBpbiB0ZXJtcyBvZiBhIHNpbmdsZSAuX2ludm9rZSBtZXRob2QuXG4gIGZ1bmN0aW9uIGRlZmluZUl0ZXJhdG9yTWV0aG9kcyhwcm90b3R5cGUpIHtcbiAgICBbXCJuZXh0XCIsIFwidGhyb3dcIiwgXCJyZXR1cm5cIl0uZm9yRWFjaChmdW5jdGlvbihtZXRob2QpIHtcbiAgICAgIGRlZmluZShwcm90b3R5cGUsIG1ldGhvZCwgZnVuY3Rpb24oYXJnKSB7XG4gICAgICAgIHJldHVybiB0aGlzLl9pbnZva2UobWV0aG9kLCBhcmcpO1xuICAgICAgfSk7XG4gICAgfSk7XG4gIH1cblxuICBleHBvcnRzLmlzR2VuZXJhdG9yRnVuY3Rpb24gPSBmdW5jdGlvbihnZW5GdW4pIHtcbiAgICB2YXIgY3RvciA9IHR5cGVvZiBnZW5GdW4gPT09IFwiZnVuY3Rpb25cIiAmJiBnZW5GdW4uY29uc3RydWN0b3I7XG4gICAgcmV0dXJuIGN0b3JcbiAgICAgID8gY3RvciA9PT0gR2VuZXJhdG9yRnVuY3Rpb24gfHxcbiAgICAgICAgLy8gRm9yIHRoZSBuYXRpdmUgR2VuZXJhdG9yRnVuY3Rpb24gY29uc3RydWN0b3IsIHRoZSBiZXN0IHdlIGNhblxuICAgICAgICAvLyBkbyBpcyB0byBjaGVjayBpdHMgLm5hbWUgcHJvcGVydHkuXG4gICAgICAgIChjdG9yLmRpc3BsYXlOYW1lIHx8IGN0b3IubmFtZSkgPT09IFwiR2VuZXJhdG9yRnVuY3Rpb25cIlxuICAgICAgOiBmYWxzZTtcbiAgfTtcblxuICBleHBvcnRzLm1hcmsgPSBmdW5jdGlvbihnZW5GdW4pIHtcbiAgICBpZiAoT2JqZWN0LnNldFByb3RvdHlwZU9mKSB7XG4gICAgICBPYmplY3Quc2V0UHJvdG90eXBlT2YoZ2VuRnVuLCBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGdlbkZ1bi5fX3Byb3RvX18gPSBHZW5lcmF0b3JGdW5jdGlvblByb3RvdHlwZTtcbiAgICAgIGRlZmluZShnZW5GdW4sIHRvU3RyaW5nVGFnU3ltYm9sLCBcIkdlbmVyYXRvckZ1bmN0aW9uXCIpO1xuICAgIH1cbiAgICBnZW5GdW4ucHJvdG90eXBlID0gT2JqZWN0LmNyZWF0ZShHcCk7XG4gICAgcmV0dXJuIGdlbkZ1bjtcbiAgfTtcblxuICAvLyBXaXRoaW4gdGhlIGJvZHkgb2YgYW55IGFzeW5jIGZ1bmN0aW9uLCBgYXdhaXQgeGAgaXMgdHJhbnNmb3JtZWQgdG9cbiAgLy8gYHlpZWxkIHJlZ2VuZXJhdG9yUnVudGltZS5hd3JhcCh4KWAsIHNvIHRoYXQgdGhlIHJ1bnRpbWUgY2FuIHRlc3RcbiAgLy8gYGhhc093bi5jYWxsKHZhbHVlLCBcIl9fYXdhaXRcIilgIHRvIGRldGVybWluZSBpZiB0aGUgeWllbGRlZCB2YWx1ZSBpc1xuICAvLyBtZWFudCB0byBiZSBhd2FpdGVkLlxuICBleHBvcnRzLmF3cmFwID0gZnVuY3Rpb24oYXJnKSB7XG4gICAgcmV0dXJuIHsgX19hd2FpdDogYXJnIH07XG4gIH07XG5cbiAgZnVuY3Rpb24gQXN5bmNJdGVyYXRvcihnZW5lcmF0b3IsIFByb21pc2VJbXBsKSB7XG4gICAgZnVuY3Rpb24gaW52b2tlKG1ldGhvZCwgYXJnLCByZXNvbHZlLCByZWplY3QpIHtcbiAgICAgIHZhciByZWNvcmQgPSB0cnlDYXRjaChnZW5lcmF0b3JbbWV0aG9kXSwgZ2VuZXJhdG9yLCBhcmcpO1xuICAgICAgaWYgKHJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgICAgcmVqZWN0KHJlY29yZC5hcmcpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdmFyIHJlc3VsdCA9IHJlY29yZC5hcmc7XG4gICAgICAgIHZhciB2YWx1ZSA9IHJlc3VsdC52YWx1ZTtcbiAgICAgICAgaWYgKHZhbHVlICYmXG4gICAgICAgICAgICB0eXBlb2YgdmFsdWUgPT09IFwib2JqZWN0XCIgJiZcbiAgICAgICAgICAgIGhhc093bi5jYWxsKHZhbHVlLCBcIl9fYXdhaXRcIikpIHtcbiAgICAgICAgICByZXR1cm4gUHJvbWlzZUltcGwucmVzb2x2ZSh2YWx1ZS5fX2F3YWl0KS50aGVuKGZ1bmN0aW9uKHZhbHVlKSB7XG4gICAgICAgICAgICBpbnZva2UoXCJuZXh0XCIsIHZhbHVlLCByZXNvbHZlLCByZWplY3QpO1xuICAgICAgICAgIH0sIGZ1bmN0aW9uKGVycikge1xuICAgICAgICAgICAgaW52b2tlKFwidGhyb3dcIiwgZXJyLCByZXNvbHZlLCByZWplY3QpO1xuICAgICAgICAgIH0pO1xuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuIFByb21pc2VJbXBsLnJlc29sdmUodmFsdWUpLnRoZW4oZnVuY3Rpb24odW53cmFwcGVkKSB7XG4gICAgICAgICAgLy8gV2hlbiBhIHlpZWxkZWQgUHJvbWlzZSBpcyByZXNvbHZlZCwgaXRzIGZpbmFsIHZhbHVlIGJlY29tZXNcbiAgICAgICAgICAvLyB0aGUgLnZhbHVlIG9mIHRoZSBQcm9taXNlPHt2YWx1ZSxkb25lfT4gcmVzdWx0IGZvciB0aGVcbiAgICAgICAgICAvLyBjdXJyZW50IGl0ZXJhdGlvbi5cbiAgICAgICAgICByZXN1bHQudmFsdWUgPSB1bndyYXBwZWQ7XG4gICAgICAgICAgcmVzb2x2ZShyZXN1bHQpO1xuICAgICAgICB9LCBmdW5jdGlvbihlcnJvcikge1xuICAgICAgICAgIC8vIElmIGEgcmVqZWN0ZWQgUHJvbWlzZSB3YXMgeWllbGRlZCwgdGhyb3cgdGhlIHJlamVjdGlvbiBiYWNrXG4gICAgICAgICAgLy8gaW50byB0aGUgYXN5bmMgZ2VuZXJhdG9yIGZ1bmN0aW9uIHNvIGl0IGNhbiBiZSBoYW5kbGVkIHRoZXJlLlxuICAgICAgICAgIHJldHVybiBpbnZva2UoXCJ0aHJvd1wiLCBlcnJvciwgcmVzb2x2ZSwgcmVqZWN0KTtcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfVxuXG4gICAgdmFyIHByZXZpb3VzUHJvbWlzZTtcblxuICAgIGZ1bmN0aW9uIGVucXVldWUobWV0aG9kLCBhcmcpIHtcbiAgICAgIGZ1bmN0aW9uIGNhbGxJbnZva2VXaXRoTWV0aG9kQW5kQXJnKCkge1xuICAgICAgICByZXR1cm4gbmV3IFByb21pc2VJbXBsKGZ1bmN0aW9uKHJlc29sdmUsIHJlamVjdCkge1xuICAgICAgICAgIGludm9rZShtZXRob2QsIGFyZywgcmVzb2x2ZSwgcmVqZWN0KTtcbiAgICAgICAgfSk7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiBwcmV2aW91c1Byb21pc2UgPVxuICAgICAgICAvLyBJZiBlbnF1ZXVlIGhhcyBiZWVuIGNhbGxlZCBiZWZvcmUsIHRoZW4gd2Ugd2FudCB0byB3YWl0IHVudGlsXG4gICAgICAgIC8vIGFsbCBwcmV2aW91cyBQcm9taXNlcyBoYXZlIGJlZW4gcmVzb2x2ZWQgYmVmb3JlIGNhbGxpbmcgaW52b2tlLFxuICAgICAgICAvLyBzbyB0aGF0IHJlc3VsdHMgYXJlIGFsd2F5cyBkZWxpdmVyZWQgaW4gdGhlIGNvcnJlY3Qgb3JkZXIuIElmXG4gICAgICAgIC8vIGVucXVldWUgaGFzIG5vdCBiZWVuIGNhbGxlZCBiZWZvcmUsIHRoZW4gaXQgaXMgaW1wb3J0YW50IHRvXG4gICAgICAgIC8vIGNhbGwgaW52b2tlIGltbWVkaWF0ZWx5LCB3aXRob3V0IHdhaXRpbmcgb24gYSBjYWxsYmFjayB0byBmaXJlLFxuICAgICAgICAvLyBzbyB0aGF0IHRoZSBhc3luYyBnZW5lcmF0b3IgZnVuY3Rpb24gaGFzIHRoZSBvcHBvcnR1bml0eSB0byBkb1xuICAgICAgICAvLyBhbnkgbmVjZXNzYXJ5IHNldHVwIGluIGEgcHJlZGljdGFibGUgd2F5LiBUaGlzIHByZWRpY3RhYmlsaXR5XG4gICAgICAgIC8vIGlzIHdoeSB0aGUgUHJvbWlzZSBjb25zdHJ1Y3RvciBzeW5jaHJvbm91c2x5IGludm9rZXMgaXRzXG4gICAgICAgIC8vIGV4ZWN1dG9yIGNhbGxiYWNrLCBhbmQgd2h5IGFzeW5jIGZ1bmN0aW9ucyBzeW5jaHJvbm91c2x5XG4gICAgICAgIC8vIGV4ZWN1dGUgY29kZSBiZWZvcmUgdGhlIGZpcnN0IGF3YWl0LiBTaW5jZSB3ZSBpbXBsZW1lbnQgc2ltcGxlXG4gICAgICAgIC8vIGFzeW5jIGZ1bmN0aW9ucyBpbiB0ZXJtcyBvZiBhc3luYyBnZW5lcmF0b3JzLCBpdCBpcyBlc3BlY2lhbGx5XG4gICAgICAgIC8vIGltcG9ydGFudCB0byBnZXQgdGhpcyByaWdodCwgZXZlbiB0aG91Z2ggaXQgcmVxdWlyZXMgY2FyZS5cbiAgICAgICAgcHJldmlvdXNQcm9taXNlID8gcHJldmlvdXNQcm9taXNlLnRoZW4oXG4gICAgICAgICAgY2FsbEludm9rZVdpdGhNZXRob2RBbmRBcmcsXG4gICAgICAgICAgLy8gQXZvaWQgcHJvcGFnYXRpbmcgZmFpbHVyZXMgdG8gUHJvbWlzZXMgcmV0dXJuZWQgYnkgbGF0ZXJcbiAgICAgICAgICAvLyBpbnZvY2F0aW9ucyBvZiB0aGUgaXRlcmF0b3IuXG4gICAgICAgICAgY2FsbEludm9rZVdpdGhNZXRob2RBbmRBcmdcbiAgICAgICAgKSA6IGNhbGxJbnZva2VXaXRoTWV0aG9kQW5kQXJnKCk7XG4gICAgfVxuXG4gICAgLy8gRGVmaW5lIHRoZSB1bmlmaWVkIGhlbHBlciBtZXRob2QgdGhhdCBpcyB1c2VkIHRvIGltcGxlbWVudCAubmV4dCxcbiAgICAvLyAudGhyb3csIGFuZCAucmV0dXJuIChzZWUgZGVmaW5lSXRlcmF0b3JNZXRob2RzKS5cbiAgICB0aGlzLl9pbnZva2UgPSBlbnF1ZXVlO1xuICB9XG5cbiAgZGVmaW5lSXRlcmF0b3JNZXRob2RzKEFzeW5jSXRlcmF0b3IucHJvdG90eXBlKTtcbiAgQXN5bmNJdGVyYXRvci5wcm90b3R5cGVbYXN5bmNJdGVyYXRvclN5bWJvbF0gPSBmdW5jdGlvbiAoKSB7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH07XG4gIGV4cG9ydHMuQXN5bmNJdGVyYXRvciA9IEFzeW5jSXRlcmF0b3I7XG5cbiAgLy8gTm90ZSB0aGF0IHNpbXBsZSBhc3luYyBmdW5jdGlvbnMgYXJlIGltcGxlbWVudGVkIG9uIHRvcCBvZlxuICAvLyBBc3luY0l0ZXJhdG9yIG9iamVjdHM7IHRoZXkganVzdCByZXR1cm4gYSBQcm9taXNlIGZvciB0aGUgdmFsdWUgb2ZcbiAgLy8gdGhlIGZpbmFsIHJlc3VsdCBwcm9kdWNlZCBieSB0aGUgaXRlcmF0b3IuXG4gIGV4cG9ydHMuYXN5bmMgPSBmdW5jdGlvbihpbm5lckZuLCBvdXRlckZuLCBzZWxmLCB0cnlMb2NzTGlzdCwgUHJvbWlzZUltcGwpIHtcbiAgICBpZiAoUHJvbWlzZUltcGwgPT09IHZvaWQgMCkgUHJvbWlzZUltcGwgPSBQcm9taXNlO1xuXG4gICAgdmFyIGl0ZXIgPSBuZXcgQXN5bmNJdGVyYXRvcihcbiAgICAgIHdyYXAoaW5uZXJGbiwgb3V0ZXJGbiwgc2VsZiwgdHJ5TG9jc0xpc3QpLFxuICAgICAgUHJvbWlzZUltcGxcbiAgICApO1xuXG4gICAgcmV0dXJuIGV4cG9ydHMuaXNHZW5lcmF0b3JGdW5jdGlvbihvdXRlckZuKVxuICAgICAgPyBpdGVyIC8vIElmIG91dGVyRm4gaXMgYSBnZW5lcmF0b3IsIHJldHVybiB0aGUgZnVsbCBpdGVyYXRvci5cbiAgICAgIDogaXRlci5uZXh0KCkudGhlbihmdW5jdGlvbihyZXN1bHQpIHtcbiAgICAgICAgICByZXR1cm4gcmVzdWx0LmRvbmUgPyByZXN1bHQudmFsdWUgOiBpdGVyLm5leHQoKTtcbiAgICAgICAgfSk7XG4gIH07XG5cbiAgZnVuY3Rpb24gbWFrZUludm9rZU1ldGhvZChpbm5lckZuLCBzZWxmLCBjb250ZXh0KSB7XG4gICAgdmFyIHN0YXRlID0gR2VuU3RhdGVTdXNwZW5kZWRTdGFydDtcblxuICAgIHJldHVybiBmdW5jdGlvbiBpbnZva2UobWV0aG9kLCBhcmcpIHtcbiAgICAgIGlmIChzdGF0ZSA9PT0gR2VuU3RhdGVFeGVjdXRpbmcpIHtcbiAgICAgICAgdGhyb3cgbmV3IEVycm9yKFwiR2VuZXJhdG9yIGlzIGFscmVhZHkgcnVubmluZ1wiKTtcbiAgICAgIH1cblxuICAgICAgaWYgKHN0YXRlID09PSBHZW5TdGF0ZUNvbXBsZXRlZCkge1xuICAgICAgICBpZiAobWV0aG9kID09PSBcInRocm93XCIpIHtcbiAgICAgICAgICB0aHJvdyBhcmc7XG4gICAgICAgIH1cblxuICAgICAgICAvLyBCZSBmb3JnaXZpbmcsIHBlciAyNS4zLjMuMy4zIG9mIHRoZSBzcGVjOlxuICAgICAgICAvLyBodHRwczovL3Blb3BsZS5tb3ppbGxhLm9yZy9+am9yZW5kb3JmZi9lczYtZHJhZnQuaHRtbCNzZWMtZ2VuZXJhdG9ycmVzdW1lXG4gICAgICAgIHJldHVybiBkb25lUmVzdWx0KCk7XG4gICAgICB9XG5cbiAgICAgIGNvbnRleHQubWV0aG9kID0gbWV0aG9kO1xuICAgICAgY29udGV4dC5hcmcgPSBhcmc7XG5cbiAgICAgIHdoaWxlICh0cnVlKSB7XG4gICAgICAgIHZhciBkZWxlZ2F0ZSA9IGNvbnRleHQuZGVsZWdhdGU7XG4gICAgICAgIGlmIChkZWxlZ2F0ZSkge1xuICAgICAgICAgIHZhciBkZWxlZ2F0ZVJlc3VsdCA9IG1heWJlSW52b2tlRGVsZWdhdGUoZGVsZWdhdGUsIGNvbnRleHQpO1xuICAgICAgICAgIGlmIChkZWxlZ2F0ZVJlc3VsdCkge1xuICAgICAgICAgICAgaWYgKGRlbGVnYXRlUmVzdWx0ID09PSBDb250aW51ZVNlbnRpbmVsKSBjb250aW51ZTtcbiAgICAgICAgICAgIHJldHVybiBkZWxlZ2F0ZVJlc3VsdDtcbiAgICAgICAgICB9XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoY29udGV4dC5tZXRob2QgPT09IFwibmV4dFwiKSB7XG4gICAgICAgICAgLy8gU2V0dGluZyBjb250ZXh0Ll9zZW50IGZvciBsZWdhY3kgc3VwcG9ydCBvZiBCYWJlbCdzXG4gICAgICAgICAgLy8gZnVuY3Rpb24uc2VudCBpbXBsZW1lbnRhdGlvbi5cbiAgICAgICAgICBjb250ZXh0LnNlbnQgPSBjb250ZXh0Ll9zZW50ID0gY29udGV4dC5hcmc7XG5cbiAgICAgICAgfSBlbHNlIGlmIChjb250ZXh0Lm1ldGhvZCA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgICAgaWYgKHN0YXRlID09PSBHZW5TdGF0ZVN1c3BlbmRlZFN0YXJ0KSB7XG4gICAgICAgICAgICBzdGF0ZSA9IEdlblN0YXRlQ29tcGxldGVkO1xuICAgICAgICAgICAgdGhyb3cgY29udGV4dC5hcmc7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgY29udGV4dC5kaXNwYXRjaEV4Y2VwdGlvbihjb250ZXh0LmFyZyk7XG5cbiAgICAgICAgfSBlbHNlIGlmIChjb250ZXh0Lm1ldGhvZCA9PT0gXCJyZXR1cm5cIikge1xuICAgICAgICAgIGNvbnRleHQuYWJydXB0KFwicmV0dXJuXCIsIGNvbnRleHQuYXJnKTtcbiAgICAgICAgfVxuXG4gICAgICAgIHN0YXRlID0gR2VuU3RhdGVFeGVjdXRpbmc7XG5cbiAgICAgICAgdmFyIHJlY29yZCA9IHRyeUNhdGNoKGlubmVyRm4sIHNlbGYsIGNvbnRleHQpO1xuICAgICAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwibm9ybWFsXCIpIHtcbiAgICAgICAgICAvLyBJZiBhbiBleGNlcHRpb24gaXMgdGhyb3duIGZyb20gaW5uZXJGbiwgd2UgbGVhdmUgc3RhdGUgPT09XG4gICAgICAgICAgLy8gR2VuU3RhdGVFeGVjdXRpbmcgYW5kIGxvb3AgYmFjayBmb3IgYW5vdGhlciBpbnZvY2F0aW9uLlxuICAgICAgICAgIHN0YXRlID0gY29udGV4dC5kb25lXG4gICAgICAgICAgICA/IEdlblN0YXRlQ29tcGxldGVkXG4gICAgICAgICAgICA6IEdlblN0YXRlU3VzcGVuZGVkWWllbGQ7XG5cbiAgICAgICAgICBpZiAocmVjb3JkLmFyZyA9PT0gQ29udGludWVTZW50aW5lbCkge1xuICAgICAgICAgICAgY29udGludWU7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgcmV0dXJuIHtcbiAgICAgICAgICAgIHZhbHVlOiByZWNvcmQuYXJnLFxuICAgICAgICAgICAgZG9uZTogY29udGV4dC5kb25lXG4gICAgICAgICAgfTtcblxuICAgICAgICB9IGVsc2UgaWYgKHJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgICAgICBzdGF0ZSA9IEdlblN0YXRlQ29tcGxldGVkO1xuICAgICAgICAgIC8vIERpc3BhdGNoIHRoZSBleGNlcHRpb24gYnkgbG9vcGluZyBiYWNrIGFyb3VuZCB0byB0aGVcbiAgICAgICAgICAvLyBjb250ZXh0LmRpc3BhdGNoRXhjZXB0aW9uKGNvbnRleHQuYXJnKSBjYWxsIGFib3ZlLlxuICAgICAgICAgIGNvbnRleHQubWV0aG9kID0gXCJ0aHJvd1wiO1xuICAgICAgICAgIGNvbnRleHQuYXJnID0gcmVjb3JkLmFyZztcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH07XG4gIH1cblxuICAvLyBDYWxsIGRlbGVnYXRlLml0ZXJhdG9yW2NvbnRleHQubWV0aG9kXShjb250ZXh0LmFyZykgYW5kIGhhbmRsZSB0aGVcbiAgLy8gcmVzdWx0LCBlaXRoZXIgYnkgcmV0dXJuaW5nIGEgeyB2YWx1ZSwgZG9uZSB9IHJlc3VsdCBmcm9tIHRoZVxuICAvLyBkZWxlZ2F0ZSBpdGVyYXRvciwgb3IgYnkgbW9kaWZ5aW5nIGNvbnRleHQubWV0aG9kIGFuZCBjb250ZXh0LmFyZyxcbiAgLy8gc2V0dGluZyBjb250ZXh0LmRlbGVnYXRlIHRvIG51bGwsIGFuZCByZXR1cm5pbmcgdGhlIENvbnRpbnVlU2VudGluZWwuXG4gIGZ1bmN0aW9uIG1heWJlSW52b2tlRGVsZWdhdGUoZGVsZWdhdGUsIGNvbnRleHQpIHtcbiAgICB2YXIgbWV0aG9kID0gZGVsZWdhdGUuaXRlcmF0b3JbY29udGV4dC5tZXRob2RdO1xuICAgIGlmIChtZXRob2QgPT09IHVuZGVmaW5lZCkge1xuICAgICAgLy8gQSAudGhyb3cgb3IgLnJldHVybiB3aGVuIHRoZSBkZWxlZ2F0ZSBpdGVyYXRvciBoYXMgbm8gLnRocm93XG4gICAgICAvLyBtZXRob2QgYWx3YXlzIHRlcm1pbmF0ZXMgdGhlIHlpZWxkKiBsb29wLlxuICAgICAgY29udGV4dC5kZWxlZ2F0ZSA9IG51bGw7XG5cbiAgICAgIGlmIChjb250ZXh0Lm1ldGhvZCA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgIC8vIE5vdGU6IFtcInJldHVyblwiXSBtdXN0IGJlIHVzZWQgZm9yIEVTMyBwYXJzaW5nIGNvbXBhdGliaWxpdHkuXG4gICAgICAgIGlmIChkZWxlZ2F0ZS5pdGVyYXRvcltcInJldHVyblwiXSkge1xuICAgICAgICAgIC8vIElmIHRoZSBkZWxlZ2F0ZSBpdGVyYXRvciBoYXMgYSByZXR1cm4gbWV0aG9kLCBnaXZlIGl0IGFcbiAgICAgICAgICAvLyBjaGFuY2UgdG8gY2xlYW4gdXAuXG4gICAgICAgICAgY29udGV4dC5tZXRob2QgPSBcInJldHVyblwiO1xuICAgICAgICAgIGNvbnRleHQuYXJnID0gdW5kZWZpbmVkO1xuICAgICAgICAgIG1heWJlSW52b2tlRGVsZWdhdGUoZGVsZWdhdGUsIGNvbnRleHQpO1xuXG4gICAgICAgICAgaWYgKGNvbnRleHQubWV0aG9kID09PSBcInRocm93XCIpIHtcbiAgICAgICAgICAgIC8vIElmIG1heWJlSW52b2tlRGVsZWdhdGUoY29udGV4dCkgY2hhbmdlZCBjb250ZXh0Lm1ldGhvZCBmcm9tXG4gICAgICAgICAgICAvLyBcInJldHVyblwiIHRvIFwidGhyb3dcIiwgbGV0IHRoYXQgb3ZlcnJpZGUgdGhlIFR5cGVFcnJvciBiZWxvdy5cbiAgICAgICAgICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuXG4gICAgICAgIGNvbnRleHQubWV0aG9kID0gXCJ0aHJvd1wiO1xuICAgICAgICBjb250ZXh0LmFyZyA9IG5ldyBUeXBlRXJyb3IoXG4gICAgICAgICAgXCJUaGUgaXRlcmF0b3IgZG9lcyBub3QgcHJvdmlkZSBhICd0aHJvdycgbWV0aG9kXCIpO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICB9XG5cbiAgICB2YXIgcmVjb3JkID0gdHJ5Q2F0Y2gobWV0aG9kLCBkZWxlZ2F0ZS5pdGVyYXRvciwgY29udGV4dC5hcmcpO1xuXG4gICAgaWYgKHJlY29yZC50eXBlID09PSBcInRocm93XCIpIHtcbiAgICAgIGNvbnRleHQubWV0aG9kID0gXCJ0aHJvd1wiO1xuICAgICAgY29udGV4dC5hcmcgPSByZWNvcmQuYXJnO1xuICAgICAgY29udGV4dC5kZWxlZ2F0ZSA9IG51bGw7XG4gICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICB9XG5cbiAgICB2YXIgaW5mbyA9IHJlY29yZC5hcmc7XG5cbiAgICBpZiAoISBpbmZvKSB7XG4gICAgICBjb250ZXh0Lm1ldGhvZCA9IFwidGhyb3dcIjtcbiAgICAgIGNvbnRleHQuYXJnID0gbmV3IFR5cGVFcnJvcihcIml0ZXJhdG9yIHJlc3VsdCBpcyBub3QgYW4gb2JqZWN0XCIpO1xuICAgICAgY29udGV4dC5kZWxlZ2F0ZSA9IG51bGw7XG4gICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICB9XG5cbiAgICBpZiAoaW5mby5kb25lKSB7XG4gICAgICAvLyBBc3NpZ24gdGhlIHJlc3VsdCBvZiB0aGUgZmluaXNoZWQgZGVsZWdhdGUgdG8gdGhlIHRlbXBvcmFyeVxuICAgICAgLy8gdmFyaWFibGUgc3BlY2lmaWVkIGJ5IGRlbGVnYXRlLnJlc3VsdE5hbWUgKHNlZSBkZWxlZ2F0ZVlpZWxkKS5cbiAgICAgIGNvbnRleHRbZGVsZWdhdGUucmVzdWx0TmFtZV0gPSBpbmZvLnZhbHVlO1xuXG4gICAgICAvLyBSZXN1bWUgZXhlY3V0aW9uIGF0IHRoZSBkZXNpcmVkIGxvY2F0aW9uIChzZWUgZGVsZWdhdGVZaWVsZCkuXG4gICAgICBjb250ZXh0Lm5leHQgPSBkZWxlZ2F0ZS5uZXh0TG9jO1xuXG4gICAgICAvLyBJZiBjb250ZXh0Lm1ldGhvZCB3YXMgXCJ0aHJvd1wiIGJ1dCB0aGUgZGVsZWdhdGUgaGFuZGxlZCB0aGVcbiAgICAgIC8vIGV4Y2VwdGlvbiwgbGV0IHRoZSBvdXRlciBnZW5lcmF0b3IgcHJvY2VlZCBub3JtYWxseS4gSWZcbiAgICAgIC8vIGNvbnRleHQubWV0aG9kIHdhcyBcIm5leHRcIiwgZm9yZ2V0IGNvbnRleHQuYXJnIHNpbmNlIGl0IGhhcyBiZWVuXG4gICAgICAvLyBcImNvbnN1bWVkXCIgYnkgdGhlIGRlbGVnYXRlIGl0ZXJhdG9yLiBJZiBjb250ZXh0Lm1ldGhvZCB3YXNcbiAgICAgIC8vIFwicmV0dXJuXCIsIGFsbG93IHRoZSBvcmlnaW5hbCAucmV0dXJuIGNhbGwgdG8gY29udGludWUgaW4gdGhlXG4gICAgICAvLyBvdXRlciBnZW5lcmF0b3IuXG4gICAgICBpZiAoY29udGV4dC5tZXRob2QgIT09IFwicmV0dXJuXCIpIHtcbiAgICAgICAgY29udGV4dC5tZXRob2QgPSBcIm5leHRcIjtcbiAgICAgICAgY29udGV4dC5hcmcgPSB1bmRlZmluZWQ7XG4gICAgICB9XG5cbiAgICB9IGVsc2Uge1xuICAgICAgLy8gUmUteWllbGQgdGhlIHJlc3VsdCByZXR1cm5lZCBieSB0aGUgZGVsZWdhdGUgbWV0aG9kLlxuICAgICAgcmV0dXJuIGluZm87XG4gICAgfVxuXG4gICAgLy8gVGhlIGRlbGVnYXRlIGl0ZXJhdG9yIGlzIGZpbmlzaGVkLCBzbyBmb3JnZXQgaXQgYW5kIGNvbnRpbnVlIHdpdGhcbiAgICAvLyB0aGUgb3V0ZXIgZ2VuZXJhdG9yLlxuICAgIGNvbnRleHQuZGVsZWdhdGUgPSBudWxsO1xuICAgIHJldHVybiBDb250aW51ZVNlbnRpbmVsO1xuICB9XG5cbiAgLy8gRGVmaW5lIEdlbmVyYXRvci5wcm90b3R5cGUue25leHQsdGhyb3cscmV0dXJufSBpbiB0ZXJtcyBvZiB0aGVcbiAgLy8gdW5pZmllZCAuX2ludm9rZSBoZWxwZXIgbWV0aG9kLlxuICBkZWZpbmVJdGVyYXRvck1ldGhvZHMoR3ApO1xuXG4gIGRlZmluZShHcCwgdG9TdHJpbmdUYWdTeW1ib2wsIFwiR2VuZXJhdG9yXCIpO1xuXG4gIC8vIEEgR2VuZXJhdG9yIHNob3VsZCBhbHdheXMgcmV0dXJuIGl0c2VsZiBhcyB0aGUgaXRlcmF0b3Igb2JqZWN0IHdoZW4gdGhlXG4gIC8vIEBAaXRlcmF0b3IgZnVuY3Rpb24gaXMgY2FsbGVkIG9uIGl0LiBTb21lIGJyb3dzZXJzJyBpbXBsZW1lbnRhdGlvbnMgb2YgdGhlXG4gIC8vIGl0ZXJhdG9yIHByb3RvdHlwZSBjaGFpbiBpbmNvcnJlY3RseSBpbXBsZW1lbnQgdGhpcywgY2F1c2luZyB0aGUgR2VuZXJhdG9yXG4gIC8vIG9iamVjdCB0byBub3QgYmUgcmV0dXJuZWQgZnJvbSB0aGlzIGNhbGwuIFRoaXMgZW5zdXJlcyB0aGF0IGRvZXNuJ3QgaGFwcGVuLlxuICAvLyBTZWUgaHR0cHM6Ly9naXRodWIuY29tL2ZhY2Vib29rL3JlZ2VuZXJhdG9yL2lzc3Vlcy8yNzQgZm9yIG1vcmUgZGV0YWlscy5cbiAgR3BbaXRlcmF0b3JTeW1ib2xdID0gZnVuY3Rpb24oKSB7XG4gICAgcmV0dXJuIHRoaXM7XG4gIH07XG5cbiAgR3AudG9TdHJpbmcgPSBmdW5jdGlvbigpIHtcbiAgICByZXR1cm4gXCJbb2JqZWN0IEdlbmVyYXRvcl1cIjtcbiAgfTtcblxuICBmdW5jdGlvbiBwdXNoVHJ5RW50cnkobG9jcykge1xuICAgIHZhciBlbnRyeSA9IHsgdHJ5TG9jOiBsb2NzWzBdIH07XG5cbiAgICBpZiAoMSBpbiBsb2NzKSB7XG4gICAgICBlbnRyeS5jYXRjaExvYyA9IGxvY3NbMV07XG4gICAgfVxuXG4gICAgaWYgKDIgaW4gbG9jcykge1xuICAgICAgZW50cnkuZmluYWxseUxvYyA9IGxvY3NbMl07XG4gICAgICBlbnRyeS5hZnRlckxvYyA9IGxvY3NbM107XG4gICAgfVxuXG4gICAgdGhpcy50cnlFbnRyaWVzLnB1c2goZW50cnkpO1xuICB9XG5cbiAgZnVuY3Rpb24gcmVzZXRUcnlFbnRyeShlbnRyeSkge1xuICAgIHZhciByZWNvcmQgPSBlbnRyeS5jb21wbGV0aW9uIHx8IHt9O1xuICAgIHJlY29yZC50eXBlID0gXCJub3JtYWxcIjtcbiAgICBkZWxldGUgcmVjb3JkLmFyZztcbiAgICBlbnRyeS5jb21wbGV0aW9uID0gcmVjb3JkO1xuICB9XG5cbiAgZnVuY3Rpb24gQ29udGV4dCh0cnlMb2NzTGlzdCkge1xuICAgIC8vIFRoZSByb290IGVudHJ5IG9iamVjdCAoZWZmZWN0aXZlbHkgYSB0cnkgc3RhdGVtZW50IHdpdGhvdXQgYSBjYXRjaFxuICAgIC8vIG9yIGEgZmluYWxseSBibG9jaykgZ2l2ZXMgdXMgYSBwbGFjZSB0byBzdG9yZSB2YWx1ZXMgdGhyb3duIGZyb21cbiAgICAvLyBsb2NhdGlvbnMgd2hlcmUgdGhlcmUgaXMgbm8gZW5jbG9zaW5nIHRyeSBzdGF0ZW1lbnQuXG4gICAgdGhpcy50cnlFbnRyaWVzID0gW3sgdHJ5TG9jOiBcInJvb3RcIiB9XTtcbiAgICB0cnlMb2NzTGlzdC5mb3JFYWNoKHB1c2hUcnlFbnRyeSwgdGhpcyk7XG4gICAgdGhpcy5yZXNldCh0cnVlKTtcbiAgfVxuXG4gIGV4cG9ydHMua2V5cyA9IGZ1bmN0aW9uKG9iamVjdCkge1xuICAgIHZhciBrZXlzID0gW107XG4gICAgZm9yICh2YXIga2V5IGluIG9iamVjdCkge1xuICAgICAga2V5cy5wdXNoKGtleSk7XG4gICAgfVxuICAgIGtleXMucmV2ZXJzZSgpO1xuXG4gICAgLy8gUmF0aGVyIHRoYW4gcmV0dXJuaW5nIGFuIG9iamVjdCB3aXRoIGEgbmV4dCBtZXRob2QsIHdlIGtlZXBcbiAgICAvLyB0aGluZ3Mgc2ltcGxlIGFuZCByZXR1cm4gdGhlIG5leHQgZnVuY3Rpb24gaXRzZWxmLlxuICAgIHJldHVybiBmdW5jdGlvbiBuZXh0KCkge1xuICAgICAgd2hpbGUgKGtleXMubGVuZ3RoKSB7XG4gICAgICAgIHZhciBrZXkgPSBrZXlzLnBvcCgpO1xuICAgICAgICBpZiAoa2V5IGluIG9iamVjdCkge1xuICAgICAgICAgIG5leHQudmFsdWUgPSBrZXk7XG4gICAgICAgICAgbmV4dC5kb25lID0gZmFsc2U7XG4gICAgICAgICAgcmV0dXJuIG5leHQ7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgLy8gVG8gYXZvaWQgY3JlYXRpbmcgYW4gYWRkaXRpb25hbCBvYmplY3QsIHdlIGp1c3QgaGFuZyB0aGUgLnZhbHVlXG4gICAgICAvLyBhbmQgLmRvbmUgcHJvcGVydGllcyBvZmYgdGhlIG5leHQgZnVuY3Rpb24gb2JqZWN0IGl0c2VsZi4gVGhpc1xuICAgICAgLy8gYWxzbyBlbnN1cmVzIHRoYXQgdGhlIG1pbmlmaWVyIHdpbGwgbm90IGFub255bWl6ZSB0aGUgZnVuY3Rpb24uXG4gICAgICBuZXh0LmRvbmUgPSB0cnVlO1xuICAgICAgcmV0dXJuIG5leHQ7XG4gICAgfTtcbiAgfTtcblxuICBmdW5jdGlvbiB2YWx1ZXMoaXRlcmFibGUpIHtcbiAgICBpZiAoaXRlcmFibGUpIHtcbiAgICAgIHZhciBpdGVyYXRvck1ldGhvZCA9IGl0ZXJhYmxlW2l0ZXJhdG9yU3ltYm9sXTtcbiAgICAgIGlmIChpdGVyYXRvck1ldGhvZCkge1xuICAgICAgICByZXR1cm4gaXRlcmF0b3JNZXRob2QuY2FsbChpdGVyYWJsZSk7XG4gICAgICB9XG5cbiAgICAgIGlmICh0eXBlb2YgaXRlcmFibGUubmV4dCA9PT0gXCJmdW5jdGlvblwiKSB7XG4gICAgICAgIHJldHVybiBpdGVyYWJsZTtcbiAgICAgIH1cblxuICAgICAgaWYgKCFpc05hTihpdGVyYWJsZS5sZW5ndGgpKSB7XG4gICAgICAgIHZhciBpID0gLTEsIG5leHQgPSBmdW5jdGlvbiBuZXh0KCkge1xuICAgICAgICAgIHdoaWxlICgrK2kgPCBpdGVyYWJsZS5sZW5ndGgpIHtcbiAgICAgICAgICAgIGlmIChoYXNPd24uY2FsbChpdGVyYWJsZSwgaSkpIHtcbiAgICAgICAgICAgICAgbmV4dC52YWx1ZSA9IGl0ZXJhYmxlW2ldO1xuICAgICAgICAgICAgICBuZXh0LmRvbmUgPSBmYWxzZTtcbiAgICAgICAgICAgICAgcmV0dXJuIG5leHQ7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgbmV4dC52YWx1ZSA9IHVuZGVmaW5lZDtcbiAgICAgICAgICBuZXh0LmRvbmUgPSB0cnVlO1xuXG4gICAgICAgICAgcmV0dXJuIG5leHQ7XG4gICAgICAgIH07XG5cbiAgICAgICAgcmV0dXJuIG5leHQubmV4dCA9IG5leHQ7XG4gICAgICB9XG4gICAgfVxuXG4gICAgLy8gUmV0dXJuIGFuIGl0ZXJhdG9yIHdpdGggbm8gdmFsdWVzLlxuICAgIHJldHVybiB7IG5leHQ6IGRvbmVSZXN1bHQgfTtcbiAgfVxuICBleHBvcnRzLnZhbHVlcyA9IHZhbHVlcztcblxuICBmdW5jdGlvbiBkb25lUmVzdWx0KCkge1xuICAgIHJldHVybiB7IHZhbHVlOiB1bmRlZmluZWQsIGRvbmU6IHRydWUgfTtcbiAgfVxuXG4gIENvbnRleHQucHJvdG90eXBlID0ge1xuICAgIGNvbnN0cnVjdG9yOiBDb250ZXh0LFxuXG4gICAgcmVzZXQ6IGZ1bmN0aW9uKHNraXBUZW1wUmVzZXQpIHtcbiAgICAgIHRoaXMucHJldiA9IDA7XG4gICAgICB0aGlzLm5leHQgPSAwO1xuICAgICAgLy8gUmVzZXR0aW5nIGNvbnRleHQuX3NlbnQgZm9yIGxlZ2FjeSBzdXBwb3J0IG9mIEJhYmVsJ3NcbiAgICAgIC8vIGZ1bmN0aW9uLnNlbnQgaW1wbGVtZW50YXRpb24uXG4gICAgICB0aGlzLnNlbnQgPSB0aGlzLl9zZW50ID0gdW5kZWZpbmVkO1xuICAgICAgdGhpcy5kb25lID0gZmFsc2U7XG4gICAgICB0aGlzLmRlbGVnYXRlID0gbnVsbDtcblxuICAgICAgdGhpcy5tZXRob2QgPSBcIm5leHRcIjtcbiAgICAgIHRoaXMuYXJnID0gdW5kZWZpbmVkO1xuXG4gICAgICB0aGlzLnRyeUVudHJpZXMuZm9yRWFjaChyZXNldFRyeUVudHJ5KTtcblxuICAgICAgaWYgKCFza2lwVGVtcFJlc2V0KSB7XG4gICAgICAgIGZvciAodmFyIG5hbWUgaW4gdGhpcykge1xuICAgICAgICAgIC8vIE5vdCBzdXJlIGFib3V0IHRoZSBvcHRpbWFsIG9yZGVyIG9mIHRoZXNlIGNvbmRpdGlvbnM6XG4gICAgICAgICAgaWYgKG5hbWUuY2hhckF0KDApID09PSBcInRcIiAmJlxuICAgICAgICAgICAgICBoYXNPd24uY2FsbCh0aGlzLCBuYW1lKSAmJlxuICAgICAgICAgICAgICAhaXNOYU4oK25hbWUuc2xpY2UoMSkpKSB7XG4gICAgICAgICAgICB0aGlzW25hbWVdID0gdW5kZWZpbmVkO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0sXG5cbiAgICBzdG9wOiBmdW5jdGlvbigpIHtcbiAgICAgIHRoaXMuZG9uZSA9IHRydWU7XG5cbiAgICAgIHZhciByb290RW50cnkgPSB0aGlzLnRyeUVudHJpZXNbMF07XG4gICAgICB2YXIgcm9vdFJlY29yZCA9IHJvb3RFbnRyeS5jb21wbGV0aW9uO1xuICAgICAgaWYgKHJvb3RSZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgIHRocm93IHJvb3RSZWNvcmQuYXJnO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gdGhpcy5ydmFsO1xuICAgIH0sXG5cbiAgICBkaXNwYXRjaEV4Y2VwdGlvbjogZnVuY3Rpb24oZXhjZXB0aW9uKSB7XG4gICAgICBpZiAodGhpcy5kb25lKSB7XG4gICAgICAgIHRocm93IGV4Y2VwdGlvbjtcbiAgICAgIH1cblxuICAgICAgdmFyIGNvbnRleHQgPSB0aGlzO1xuICAgICAgZnVuY3Rpb24gaGFuZGxlKGxvYywgY2F1Z2h0KSB7XG4gICAgICAgIHJlY29yZC50eXBlID0gXCJ0aHJvd1wiO1xuICAgICAgICByZWNvcmQuYXJnID0gZXhjZXB0aW9uO1xuICAgICAgICBjb250ZXh0Lm5leHQgPSBsb2M7XG5cbiAgICAgICAgaWYgKGNhdWdodCkge1xuICAgICAgICAgIC8vIElmIHRoZSBkaXNwYXRjaGVkIGV4Y2VwdGlvbiB3YXMgY2F1Z2h0IGJ5IGEgY2F0Y2ggYmxvY2ssXG4gICAgICAgICAgLy8gdGhlbiBsZXQgdGhhdCBjYXRjaCBibG9jayBoYW5kbGUgdGhlIGV4Y2VwdGlvbiBub3JtYWxseS5cbiAgICAgICAgICBjb250ZXh0Lm1ldGhvZCA9IFwibmV4dFwiO1xuICAgICAgICAgIGNvbnRleHQuYXJnID0gdW5kZWZpbmVkO1xuICAgICAgICB9XG5cbiAgICAgICAgcmV0dXJuICEhIGNhdWdodDtcbiAgICAgIH1cblxuICAgICAgZm9yICh2YXIgaSA9IHRoaXMudHJ5RW50cmllcy5sZW5ndGggLSAxOyBpID49IDA7IC0taSkge1xuICAgICAgICB2YXIgZW50cnkgPSB0aGlzLnRyeUVudHJpZXNbaV07XG4gICAgICAgIHZhciByZWNvcmQgPSBlbnRyeS5jb21wbGV0aW9uO1xuXG4gICAgICAgIGlmIChlbnRyeS50cnlMb2MgPT09IFwicm9vdFwiKSB7XG4gICAgICAgICAgLy8gRXhjZXB0aW9uIHRocm93biBvdXRzaWRlIG9mIGFueSB0cnkgYmxvY2sgdGhhdCBjb3VsZCBoYW5kbGVcbiAgICAgICAgICAvLyBpdCwgc28gc2V0IHRoZSBjb21wbGV0aW9uIHZhbHVlIG9mIHRoZSBlbnRpcmUgZnVuY3Rpb24gdG9cbiAgICAgICAgICAvLyB0aHJvdyB0aGUgZXhjZXB0aW9uLlxuICAgICAgICAgIHJldHVybiBoYW5kbGUoXCJlbmRcIik7XG4gICAgICAgIH1cblxuICAgICAgICBpZiAoZW50cnkudHJ5TG9jIDw9IHRoaXMucHJldikge1xuICAgICAgICAgIHZhciBoYXNDYXRjaCA9IGhhc093bi5jYWxsKGVudHJ5LCBcImNhdGNoTG9jXCIpO1xuICAgICAgICAgIHZhciBoYXNGaW5hbGx5ID0gaGFzT3duLmNhbGwoZW50cnksIFwiZmluYWxseUxvY1wiKTtcblxuICAgICAgICAgIGlmIChoYXNDYXRjaCAmJiBoYXNGaW5hbGx5KSB7XG4gICAgICAgICAgICBpZiAodGhpcy5wcmV2IDwgZW50cnkuY2F0Y2hMb2MpIHtcbiAgICAgICAgICAgICAgcmV0dXJuIGhhbmRsZShlbnRyeS5jYXRjaExvYywgdHJ1ZSk7XG4gICAgICAgICAgICB9IGVsc2UgaWYgKHRoaXMucHJldiA8IGVudHJ5LmZpbmFsbHlMb2MpIHtcbiAgICAgICAgICAgICAgcmV0dXJuIGhhbmRsZShlbnRyeS5maW5hbGx5TG9jKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgIH0gZWxzZSBpZiAoaGFzQ2F0Y2gpIHtcbiAgICAgICAgICAgIGlmICh0aGlzLnByZXYgPCBlbnRyeS5jYXRjaExvYykge1xuICAgICAgICAgICAgICByZXR1cm4gaGFuZGxlKGVudHJ5LmNhdGNoTG9jLCB0cnVlKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgIH0gZWxzZSBpZiAoaGFzRmluYWxseSkge1xuICAgICAgICAgICAgaWYgKHRoaXMucHJldiA8IGVudHJ5LmZpbmFsbHlMb2MpIHtcbiAgICAgICAgICAgICAgcmV0dXJuIGhhbmRsZShlbnRyeS5maW5hbGx5TG9jKTtcbiAgICAgICAgICAgIH1cblxuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXCJ0cnkgc3RhdGVtZW50IHdpdGhvdXQgY2F0Y2ggb3IgZmluYWxseVwiKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9LFxuXG4gICAgYWJydXB0OiBmdW5jdGlvbih0eXBlLCBhcmcpIHtcbiAgICAgIGZvciAodmFyIGkgPSB0aGlzLnRyeUVudHJpZXMubGVuZ3RoIC0gMTsgaSA+PSAwOyAtLWkpIHtcbiAgICAgICAgdmFyIGVudHJ5ID0gdGhpcy50cnlFbnRyaWVzW2ldO1xuICAgICAgICBpZiAoZW50cnkudHJ5TG9jIDw9IHRoaXMucHJldiAmJlxuICAgICAgICAgICAgaGFzT3duLmNhbGwoZW50cnksIFwiZmluYWxseUxvY1wiKSAmJlxuICAgICAgICAgICAgdGhpcy5wcmV2IDwgZW50cnkuZmluYWxseUxvYykge1xuICAgICAgICAgIHZhciBmaW5hbGx5RW50cnkgPSBlbnRyeTtcbiAgICAgICAgICBicmVhaztcbiAgICAgICAgfVxuICAgICAgfVxuXG4gICAgICBpZiAoZmluYWxseUVudHJ5ICYmXG4gICAgICAgICAgKHR5cGUgPT09IFwiYnJlYWtcIiB8fFxuICAgICAgICAgICB0eXBlID09PSBcImNvbnRpbnVlXCIpICYmXG4gICAgICAgICAgZmluYWxseUVudHJ5LnRyeUxvYyA8PSBhcmcgJiZcbiAgICAgICAgICBhcmcgPD0gZmluYWxseUVudHJ5LmZpbmFsbHlMb2MpIHtcbiAgICAgICAgLy8gSWdub3JlIHRoZSBmaW5hbGx5IGVudHJ5IGlmIGNvbnRyb2wgaXMgbm90IGp1bXBpbmcgdG8gYVxuICAgICAgICAvLyBsb2NhdGlvbiBvdXRzaWRlIHRoZSB0cnkvY2F0Y2ggYmxvY2suXG4gICAgICAgIGZpbmFsbHlFbnRyeSA9IG51bGw7XG4gICAgICB9XG5cbiAgICAgIHZhciByZWNvcmQgPSBmaW5hbGx5RW50cnkgPyBmaW5hbGx5RW50cnkuY29tcGxldGlvbiA6IHt9O1xuICAgICAgcmVjb3JkLnR5cGUgPSB0eXBlO1xuICAgICAgcmVjb3JkLmFyZyA9IGFyZztcblxuICAgICAgaWYgKGZpbmFsbHlFbnRyeSkge1xuICAgICAgICB0aGlzLm1ldGhvZCA9IFwibmV4dFwiO1xuICAgICAgICB0aGlzLm5leHQgPSBmaW5hbGx5RW50cnkuZmluYWxseUxvYztcbiAgICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgICB9XG5cbiAgICAgIHJldHVybiB0aGlzLmNvbXBsZXRlKHJlY29yZCk7XG4gICAgfSxcblxuICAgIGNvbXBsZXRlOiBmdW5jdGlvbihyZWNvcmQsIGFmdGVyTG9jKSB7XG4gICAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwidGhyb3dcIikge1xuICAgICAgICB0aHJvdyByZWNvcmQuYXJnO1xuICAgICAgfVxuXG4gICAgICBpZiAocmVjb3JkLnR5cGUgPT09IFwiYnJlYWtcIiB8fFxuICAgICAgICAgIHJlY29yZC50eXBlID09PSBcImNvbnRpbnVlXCIpIHtcbiAgICAgICAgdGhpcy5uZXh0ID0gcmVjb3JkLmFyZztcbiAgICAgIH0gZWxzZSBpZiAocmVjb3JkLnR5cGUgPT09IFwicmV0dXJuXCIpIHtcbiAgICAgICAgdGhpcy5ydmFsID0gdGhpcy5hcmcgPSByZWNvcmQuYXJnO1xuICAgICAgICB0aGlzLm1ldGhvZCA9IFwicmV0dXJuXCI7XG4gICAgICAgIHRoaXMubmV4dCA9IFwiZW5kXCI7XG4gICAgICB9IGVsc2UgaWYgKHJlY29yZC50eXBlID09PSBcIm5vcm1hbFwiICYmIGFmdGVyTG9jKSB7XG4gICAgICAgIHRoaXMubmV4dCA9IGFmdGVyTG9jO1xuICAgICAgfVxuXG4gICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICB9LFxuXG4gICAgZmluaXNoOiBmdW5jdGlvbihmaW5hbGx5TG9jKSB7XG4gICAgICBmb3IgKHZhciBpID0gdGhpcy50cnlFbnRyaWVzLmxlbmd0aCAtIDE7IGkgPj0gMDsgLS1pKSB7XG4gICAgICAgIHZhciBlbnRyeSA9IHRoaXMudHJ5RW50cmllc1tpXTtcbiAgICAgICAgaWYgKGVudHJ5LmZpbmFsbHlMb2MgPT09IGZpbmFsbHlMb2MpIHtcbiAgICAgICAgICB0aGlzLmNvbXBsZXRlKGVudHJ5LmNvbXBsZXRpb24sIGVudHJ5LmFmdGVyTG9jKTtcbiAgICAgICAgICByZXNldFRyeUVudHJ5KGVudHJ5KTtcbiAgICAgICAgICByZXR1cm4gQ29udGludWVTZW50aW5lbDtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0sXG5cbiAgICBcImNhdGNoXCI6IGZ1bmN0aW9uKHRyeUxvYykge1xuICAgICAgZm9yICh2YXIgaSA9IHRoaXMudHJ5RW50cmllcy5sZW5ndGggLSAxOyBpID49IDA7IC0taSkge1xuICAgICAgICB2YXIgZW50cnkgPSB0aGlzLnRyeUVudHJpZXNbaV07XG4gICAgICAgIGlmIChlbnRyeS50cnlMb2MgPT09IHRyeUxvYykge1xuICAgICAgICAgIHZhciByZWNvcmQgPSBlbnRyeS5jb21wbGV0aW9uO1xuICAgICAgICAgIGlmIChyZWNvcmQudHlwZSA9PT0gXCJ0aHJvd1wiKSB7XG4gICAgICAgICAgICB2YXIgdGhyb3duID0gcmVjb3JkLmFyZztcbiAgICAgICAgICAgIHJlc2V0VHJ5RW50cnkoZW50cnkpO1xuICAgICAgICAgIH1cbiAgICAgICAgICByZXR1cm4gdGhyb3duO1xuICAgICAgICB9XG4gICAgICB9XG5cbiAgICAgIC8vIFRoZSBjb250ZXh0LmNhdGNoIG1ldGhvZCBtdXN0IG9ubHkgYmUgY2FsbGVkIHdpdGggYSBsb2NhdGlvblxuICAgICAgLy8gYXJndW1lbnQgdGhhdCBjb3JyZXNwb25kcyB0byBhIGtub3duIGNhdGNoIGJsb2NrLlxuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiaWxsZWdhbCBjYXRjaCBhdHRlbXB0XCIpO1xuICAgIH0sXG5cbiAgICBkZWxlZ2F0ZVlpZWxkOiBmdW5jdGlvbihpdGVyYWJsZSwgcmVzdWx0TmFtZSwgbmV4dExvYykge1xuICAgICAgdGhpcy5kZWxlZ2F0ZSA9IHtcbiAgICAgICAgaXRlcmF0b3I6IHZhbHVlcyhpdGVyYWJsZSksXG4gICAgICAgIHJlc3VsdE5hbWU6IHJlc3VsdE5hbWUsXG4gICAgICAgIG5leHRMb2M6IG5leHRMb2NcbiAgICAgIH07XG5cbiAgICAgIGlmICh0aGlzLm1ldGhvZCA9PT0gXCJuZXh0XCIpIHtcbiAgICAgICAgLy8gRGVsaWJlcmF0ZWx5IGZvcmdldCB0aGUgbGFzdCBzZW50IHZhbHVlIHNvIHRoYXQgd2UgZG9uJ3RcbiAgICAgICAgLy8gYWNjaWRlbnRhbGx5IHBhc3MgaXQgb24gdG8gdGhlIGRlbGVnYXRlLlxuICAgICAgICB0aGlzLmFyZyA9IHVuZGVmaW5lZDtcbiAgICAgIH1cblxuICAgICAgcmV0dXJuIENvbnRpbnVlU2VudGluZWw7XG4gICAgfVxuICB9O1xuXG4gIC8vIFJlZ2FyZGxlc3Mgb2Ygd2hldGhlciB0aGlzIHNjcmlwdCBpcyBleGVjdXRpbmcgYXMgYSBDb21tb25KUyBtb2R1bGVcbiAgLy8gb3Igbm90LCByZXR1cm4gdGhlIHJ1bnRpbWUgb2JqZWN0IHNvIHRoYXQgd2UgY2FuIGRlY2xhcmUgdGhlIHZhcmlhYmxlXG4gIC8vIHJlZ2VuZXJhdG9yUnVudGltZSBpbiB0aGUgb3V0ZXIgc2NvcGUsIHdoaWNoIGFsbG93cyB0aGlzIG1vZHVsZSB0byBiZVxuICAvLyBpbmplY3RlZCBlYXNpbHkgYnkgYGJpbi9yZWdlbmVyYXRvciAtLWluY2x1ZGUtcnVudGltZSBzY3JpcHQuanNgLlxuICByZXR1cm4gZXhwb3J0cztcblxufShcbiAgLy8gSWYgdGhpcyBzY3JpcHQgaXMgZXhlY3V0aW5nIGFzIGEgQ29tbW9uSlMgbW9kdWxlLCB1c2UgbW9kdWxlLmV4cG9ydHNcbiAgLy8gYXMgdGhlIHJlZ2VuZXJhdG9yUnVudGltZSBuYW1lc3BhY2UuIE90aGVyd2lzZSBjcmVhdGUgYSBuZXcgZW1wdHlcbiAgLy8gb2JqZWN0LiBFaXRoZXIgd2F5LCB0aGUgcmVzdWx0aW5nIG9iamVjdCB3aWxsIGJlIHVzZWQgdG8gaW5pdGlhbGl6ZVxuICAvLyB0aGUgcmVnZW5lcmF0b3JSdW50aW1lIHZhcmlhYmxlIGF0IHRoZSB0b3Agb2YgdGhpcyBmaWxlLlxuICB0eXBlb2YgbW9kdWxlID09PSBcIm9iamVjdFwiID8gbW9kdWxlLmV4cG9ydHMgOiB7fVxuKSk7XG5cbnRyeSB7XG4gIHJlZ2VuZXJhdG9yUnVudGltZSA9IHJ1bnRpbWU7XG59IGNhdGNoIChhY2NpZGVudGFsU3RyaWN0TW9kZSkge1xuICAvLyBUaGlzIG1vZHVsZSBzaG91bGQgbm90IGJlIHJ1bm5pbmcgaW4gc3RyaWN0IG1vZGUsIHNvIHRoZSBhYm92ZVxuICAvLyBhc3NpZ25tZW50IHNob3VsZCBhbHdheXMgd29yayB1bmxlc3Mgc29tZXRoaW5nIGlzIG1pc2NvbmZpZ3VyZWQuIEp1c3RcbiAgLy8gaW4gY2FzZSBydW50aW1lLmpzIGFjY2lkZW50YWxseSBydW5zIGluIHN0cmljdCBtb2RlLCB3ZSBjYW4gZXNjYXBlXG4gIC8vIHN0cmljdCBtb2RlIHVzaW5nIGEgZ2xvYmFsIEZ1bmN0aW9uIGNhbGwuIFRoaXMgY291bGQgY29uY2VpdmFibHkgZmFpbFxuICAvLyBpZiBhIENvbnRlbnQgU2VjdXJpdHkgUG9saWN5IGZvcmJpZHMgdXNpbmcgRnVuY3Rpb24sIGJ1dCBpbiB0aGF0IGNhc2VcbiAgLy8gdGhlIHByb3BlciBzb2x1dGlvbiBpcyB0byBmaXggdGhlIGFjY2lkZW50YWwgc3RyaWN0IG1vZGUgcHJvYmxlbS4gSWZcbiAgLy8geW91J3ZlIG1pc2NvbmZpZ3VyZWQgeW91ciBidW5kbGVyIHRvIGZvcmNlIHN0cmljdCBtb2RlIGFuZCBhcHBsaWVkIGFcbiAgLy8gQ1NQIHRvIGZvcmJpZCBGdW5jdGlvbiwgYW5kIHlvdSdyZSBub3Qgd2lsbGluZyB0byBmaXggZWl0aGVyIG9mIHRob3NlXG4gIC8vIHByb2JsZW1zLCBwbGVhc2UgZGV0YWlsIHlvdXIgdW5pcXVlIHByZWRpY2FtZW50IGluIGEgR2l0SHViIGlzc3VlLlxuICBGdW5jdGlvbihcInJcIiwgXCJyZWdlbmVyYXRvclJ1bnRpbWUgPSByXCIpKHJ1bnRpbWUpO1xufVxuIiwibW9kdWxlLmV4cG9ydHMgPSByZXF1aXJlKFwicmVnZW5lcmF0b3ItcnVudGltZVwiKTtcbiIsImltcG9ydCBzaW1wbGVHaXQgZnJvbSAnc2ltcGxlLWdpdCdcblxuaW1wb3J0IHsgcmVhZENoYW5nZWxvZywgcmVxdWlyZUVudiwgc2F2ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1jb3JlJ1xuXG5jb25zdCBmaW5hbGl6ZUN1cnJlbnRFbnRyeSA9IGFzeW5jKGNoYW5nZWxvZykgPT4ge1xuICBjb25zdCBjdXJyZW50RW50cnkgPSBjaGFuZ2Vsb2dbMF1cblxuICAvLyB1cGRhdGUgdGhlIGludm9sdmVkIHByb2plY3RzXG4gIGNvbnN0IGludm9sdmVkUHJvamVjdHMgPSByZXF1aXJlRW52KCdJTlZPTFZFRF9QUk9KRUNUUycpLnNwbGl0KCdcXG4nKVxuICBjdXJyZW50RW50cnkuaW52b2x2ZWRQcm9qZWN0cyA9IGludm9sdmVkUHJvamVjdHNcblxuICBjb25zdCBicmFuY2hGcm9tID0gY3VycmVudEVudHJ5LmJyYW5jaEZyb21cbiAgY29uc3QgZ2l0T3B0aW9ucyA9IHtcbiAgICBiYXNlRGlyICAgICAgICAgICAgICAgIDogcHJvY2Vzcy5jd2QoKSxcbiAgICBiaW5hcnkgICAgICAgICAgICAgICAgIDogJ2dpdCcsXG4gICAgbWF4Q29uY3VycmVudFByb2Nlc3NlcyA6IDZcbiAgfVxuICBjb25zdCBnaXQgPSBzaW1wbGVHaXQoZ2l0T3B0aW9ucylcbiAgY29uc3QgcmVzdWx0cyA9IGF3YWl0IGdpdC5yYXcoJ3Nob3J0bG9nJywgJy0tc3VtbWFyeScsICctLWVtYWlsJywgYCR7YnJhbmNoRnJvbX0uLi5IRUFEYClcbiAgY29uc3QgY29udHJpYnV0b3JzID0gcmVzdWx0c1xuICAgIC5zcGxpdCgnXFxuJylcbiAgICAubWFwKChsKSA9PiBsLnJlcGxhY2UoL15bXFxzXFxkXStcXHMrLywgJycpKVxuICAgIC5maWx0ZXIoKGwpID0+IGwubGVuZ3RoID4gMClcbiAgY3VycmVudEVudHJ5LmNvbnRyaWJ1dG9ycyA9IGNvbnRyaWJ1dG9yc1xuXG4gIC8qXG4gIFwicWFcIjoge1xuICAgICBcInRlc3RlZFZlcnNpb25cIjogXCJiZjgyMGUzMTguLi5cIixcbiAgICAgXCJ1bml0VGVzdFJlcG9ydFwiOiBcImh0dHBzOi8vLi4uXCIsXG4gICAgIFwibGludFJlcG9ydFwiOiBcImh0dHBzOi8vLi4uXCJcbiAgfVxuICAqL1xuICByZXR1cm4gY3VycmVudEVudHJ5XG59XG5cbmNvbnN0IGZpbmFsaXplQ2hhbmdlbG9nID0gYXN5bmMoKSA9PiB7XG4gIGNvbnN0IGNoYW5nZWxvZyA9IHJlYWRDaGFuZ2Vsb2coKVxuICBhd2FpdCBmaW5hbGl6ZUN1cnJlbnRFbnRyeShjaGFuZ2Vsb2cpXG4gIHNhdmVDaGFuZ2Vsb2coY2hhbmdlbG9nKVxufVxuXG5leHBvcnQgeyBmaW5hbGl6ZUN1cnJlbnRFbnRyeSwgZmluYWxpemVDaGFuZ2Vsb2cgfVxuIiwiaW1wb3J0ICogYXMgZnMgZnJvbSAnZnMnXG5cbmltcG9ydCB7IHJlYWRDaGFuZ2Vsb2cgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcblxuY29uc3QgcHJpbnRFbnRyaWVzID0gKGhvdGZpeGVzLCBsYXN0UmVsZWFzZURhdGUpID0+IHtcbiAgY29uc3QgY2hhbmdlbG9nID0gcmVhZENoYW5nZWxvZygpXG5cbiAgLy8gVE9ETzogdGhpcyBpcyBhIGJpdCBvZiBhIGxpbWl0YXRpb24gcmVxdWlyaW5nIHRoZSBzY3JpcHQgcHdkIHRvIGJlIHRoZSBwYWNrYWdlIHJvb3QuXG4gIGNvbnN0IHBhY2thZ2VDb250ZW50cyA9IGZzLnJlYWRGaWxlU3luYygncGFja2FnZS5qc29uJylcbiAgY29uc3QgcGFja2FnZURhdGEgPSBKU09OLnBhcnNlKHBhY2thZ2VDb250ZW50cylcblxuICBjb25zdCBjaGFuZ2VFbnRyaWVzID0gY2hhbmdlbG9nLm1hcChyID0+ICh7IHRpbWUgOiBuZXcgRGF0ZShyLnN0YXJ0VGltZXN0YW1wKSwgbm90ZXMgOiByLmNoYW5nZU5vdGVzLCBhdXRob3IgOiByLndvcmtJbml0aWF0b3IgfSkpXG4gICAgLmNvbmNhdChob3RmaXhlcy5tYXAociA9PiAoXG4gICAgICB7XG4gICAgICAgIHRpbWUgICAgIDogbmV3IERhdGUoci5kYXRlKSxcbiAgICAgICAgbm90ZXMgICAgOiBbci5tZXNzYWdlLnJlcGxhY2UoL15cXHMqaG90Zml4XFxzKjo/XFxzKi9pLCAnJyldLFxuICAgICAgICBhdXRob3IgICA6IHIuYXV0aG9yLmVtYWlsLFxuICAgICAgICBpc0hvdGZpeCA6IHRydWVcbiAgICAgIH1cbiAgICApKSlcbiAgICAuZmlsdGVyKHIgPT4gci50aW1lID49IGxhc3RSZWxlYXNlRGF0ZSlcbiAgLy8gd2l0aCBEYXRlcywgd2UgcmVhbGx5IHdhbnQgJz09Jywgbm90ICc9PT0nXG4gIGNoYW5nZUVudHJpZXMuc29ydCgoYSwgYikgPT4gYS50aW1lIDwgYi50aW1lID8gLTEgOiBhLnRpbWUgPT0gYi50aW1lID8gMCA6IDEpIC8vIGVzbGludC1kaXNhYmxlLWxpbmUgZXFlcWVxXG5cbiAgbGV0IHNlY3VyaXR5Tm90ZXMgPSBbXVxuICBsZXQgZHJwQmNwTm90ZXMgPSBbXVxuICBsZXQgYmFja291dE5vdGVzID0gW11cblxuICBmb3IgKGNvbnN0IGVudHJ5IG9mIGNoYW5nZWxvZykge1xuICAgIGlmIChlbnRyeS5zZWN1cml0eU5vdGVzICE9PSB1bmRlZmluZWQpIHtcbiAgICAgIHNlY3VyaXR5Tm90ZXMgPSBzZWN1cml0eU5vdGVzLmNvbmNhdChlbnRyeS5zZWN1cml0eU5vdGVzKVxuICAgIH1cbiAgICBpZiAoZW50cnkuZHJwQmNwTm90ZXMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgZHJwQmNwTm90ZXMgPSBkcnBCY3BOb3Rlcy5jb25jYXQoZW50cnkuZHJwQmNwTm90ZXMpXG4gICAgfVxuICAgIGlmIChlbnRyeS5iYWNrb3V0Tm90ZXMgIT09IHVuZGVmaW5lZCkge1xuICAgICAgYmFja291dE5vdGVzID0gYmFja291dE5vdGVzLmNvbmNhdChlbnRyeS5iYWNrb3V0Tm90ZXMpXG4gICAgfVxuICB9XG5cbiAgY29uc3QgYXR0cmliID0gKGVudHJ5KSA9PiBgXygke2VudHJ5LmF1dGhvcn07ICR7ZW50cnkudGltZS50b0lTT1N0cmluZygpfSlfYFxuXG4gIGZvciAoY29uc3QgZW50cnkgb2YgY2hhbmdlRW50cmllcykge1xuICAgIGlmIChlbnRyeS5pc0hvdGZpeCkge1xuICAgICAgY29uc29sZS5sb2coYCogXyoqaG90Zml4KipfOiAke2VudHJ5Lm5vdGVzWzBdfSAke2F0dHJpYihlbnRyeSl9YClcbiAgICB9XG4gICAgZWxzZSB7XG4gICAgICBmb3IgKGNvbnN0IG5vdGUgb2YgZW50cnkubm90ZXMpIHtcbiAgICAgICAgY29uc29sZS5sb2coYCogJHtub3RlfSAke2F0dHJpYihlbnRyeSl9YClcbiAgICAgIH1cbiAgICB9XG4gIH1cbiAgaWYgKHBhY2thZ2VEYXRhPy5saXE/LmNvbnRyYWN0cz8uc2VjdXJlIHx8IHNlY3VyaXR5Tm90ZXMubGVuZ3RoID4gMCkge1xuICAgIGNvbnNvbGUubG9nKCdcXG4jIyMgU2VjdXJpdHkgbm90ZXNcXG5cXG4nKVxuICAgIGNvbnNvbGUubG9nKGAke3NlY3VyaXR5Tm90ZXMubGVuZ3RoID09PSAwID8gJ19ub25lXycgOiBgKiAke3NlY3VyaXR5Tm90ZXMuam9pbignXFxuKiAnKX1gfWApXG4gIH1cbiAgaWYgKC8qIFRPRE86IGFuIG9yZyBzZXR0aW5nIG9yZy5zZXR0aW5ncz8uWydtYWludGFpbnMgRFJQL0JDUCddIHx8ICovIGRycEJjcE5vdGVzLmxlbmd0aCA+IDApIHtcbiAgICBjb25zb2xlLmxvZygnXFxuIyMjIERSUC9CQ1Agbm90ZXNcXG5cXG4nKVxuICAgIGNvbnNvbGUubG9nKGAke2RycEJjcE5vdGVzLmxlbmd0aCA9PT0gMCA/ICdfbm9uZV8nIDogYCogJHtkcnBCY3BOb3Rlcy5qb2luKCdcXG4qICcpfWB9YClcbiAgfVxuICBpZiAocGFja2FnZURhdGE/LmxpcT8uY29udHJhY3RzPy5bJ2hpZ2ggYXZhaWxhYmlsaXR5J10gfHwgYmFja291dE5vdGVzLmxlbmd0aCA+IDApIHtcbiAgICBjb25zb2xlLmxvZygnXFxuIyMjIEJhY2tvdXQgbm90ZXNcXG5cXG4nKVxuICAgIGNvbnNvbGUubG9nKGAke2JhY2tvdXROb3Rlcy5sZW5ndGggPT09IDAgPyAnX25vbmVfJyA6IGAqICR7YmFja291dE5vdGVzLmpvaW4oJ1xcbiogJyl9YH1gKVxuICB9XG59XG5cbmV4cG9ydCB7IHByaW50RW50cmllcyB9XG4iLCJmdW5jdGlvbiBfYXJyYXlXaXRoSG9sZXMoYXJyKSB7XG4gIGlmIChBcnJheS5pc0FycmF5KGFycikpIHJldHVybiBhcnI7XG59XG5cbm1vZHVsZS5leHBvcnRzID0gX2FycmF5V2l0aEhvbGVzO1xubW9kdWxlLmV4cG9ydHNbXCJkZWZhdWx0XCJdID0gbW9kdWxlLmV4cG9ydHMsIG1vZHVsZS5leHBvcnRzLl9fZXNNb2R1bGUgPSB0cnVlOyIsImZ1bmN0aW9uIF9pdGVyYWJsZVRvQXJyYXlMaW1pdChhcnIsIGkpIHtcbiAgdmFyIF9pID0gYXJyID09IG51bGwgPyBudWxsIDogdHlwZW9mIFN5bWJvbCAhPT0gXCJ1bmRlZmluZWRcIiAmJiBhcnJbU3ltYm9sLml0ZXJhdG9yXSB8fCBhcnJbXCJAQGl0ZXJhdG9yXCJdO1xuXG4gIGlmIChfaSA9PSBudWxsKSByZXR1cm47XG4gIHZhciBfYXJyID0gW107XG4gIHZhciBfbiA9IHRydWU7XG4gIHZhciBfZCA9IGZhbHNlO1xuXG4gIHZhciBfcywgX2U7XG5cbiAgdHJ5IHtcbiAgICBmb3IgKF9pID0gX2kuY2FsbChhcnIpOyAhKF9uID0gKF9zID0gX2kubmV4dCgpKS5kb25lKTsgX24gPSB0cnVlKSB7XG4gICAgICBfYXJyLnB1c2goX3MudmFsdWUpO1xuXG4gICAgICBpZiAoaSAmJiBfYXJyLmxlbmd0aCA9PT0gaSkgYnJlYWs7XG4gICAgfVxuICB9IGNhdGNoIChlcnIpIHtcbiAgICBfZCA9IHRydWU7XG4gICAgX2UgPSBlcnI7XG4gIH0gZmluYWxseSB7XG4gICAgdHJ5IHtcbiAgICAgIGlmICghX24gJiYgX2lbXCJyZXR1cm5cIl0gIT0gbnVsbCkgX2lbXCJyZXR1cm5cIl0oKTtcbiAgICB9IGZpbmFsbHkge1xuICAgICAgaWYgKF9kKSB0aHJvdyBfZTtcbiAgICB9XG4gIH1cblxuICByZXR1cm4gX2Fycjtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfaXRlcmFibGVUb0FycmF5TGltaXQ7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiZnVuY3Rpb24gX2FycmF5TGlrZVRvQXJyYXkoYXJyLCBsZW4pIHtcbiAgaWYgKGxlbiA9PSBudWxsIHx8IGxlbiA+IGFyci5sZW5ndGgpIGxlbiA9IGFyci5sZW5ndGg7XG5cbiAgZm9yICh2YXIgaSA9IDAsIGFycjIgPSBuZXcgQXJyYXkobGVuKTsgaSA8IGxlbjsgaSsrKSB7XG4gICAgYXJyMltpXSA9IGFycltpXTtcbiAgfVxuXG4gIHJldHVybiBhcnIyO1xufVxuXG5tb2R1bGUuZXhwb3J0cyA9IF9hcnJheUxpa2VUb0FycmF5O1xubW9kdWxlLmV4cG9ydHNbXCJkZWZhdWx0XCJdID0gbW9kdWxlLmV4cG9ydHMsIG1vZHVsZS5leHBvcnRzLl9fZXNNb2R1bGUgPSB0cnVlOyIsInZhciBhcnJheUxpa2VUb0FycmF5ID0gcmVxdWlyZShcIi4vYXJyYXlMaWtlVG9BcnJheS5qc1wiKTtcblxuZnVuY3Rpb24gX3Vuc3VwcG9ydGVkSXRlcmFibGVUb0FycmF5KG8sIG1pbkxlbikge1xuICBpZiAoIW8pIHJldHVybjtcbiAgaWYgKHR5cGVvZiBvID09PSBcInN0cmluZ1wiKSByZXR1cm4gYXJyYXlMaWtlVG9BcnJheShvLCBtaW5MZW4pO1xuICB2YXIgbiA9IE9iamVjdC5wcm90b3R5cGUudG9TdHJpbmcuY2FsbChvKS5zbGljZSg4LCAtMSk7XG4gIGlmIChuID09PSBcIk9iamVjdFwiICYmIG8uY29uc3RydWN0b3IpIG4gPSBvLmNvbnN0cnVjdG9yLm5hbWU7XG4gIGlmIChuID09PSBcIk1hcFwiIHx8IG4gPT09IFwiU2V0XCIpIHJldHVybiBBcnJheS5mcm9tKG8pO1xuICBpZiAobiA9PT0gXCJBcmd1bWVudHNcIiB8fCAvXig/OlVpfEkpbnQoPzo4fDE2fDMyKSg/OkNsYW1wZWQpP0FycmF5JC8udGVzdChuKSkgcmV0dXJuIGFycmF5TGlrZVRvQXJyYXkobywgbWluTGVuKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXk7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiZnVuY3Rpb24gX25vbkl0ZXJhYmxlUmVzdCgpIHtcbiAgdGhyb3cgbmV3IFR5cGVFcnJvcihcIkludmFsaWQgYXR0ZW1wdCB0byBkZXN0cnVjdHVyZSBub24taXRlcmFibGUgaW5zdGFuY2UuXFxuSW4gb3JkZXIgdG8gYmUgaXRlcmFibGUsIG5vbi1hcnJheSBvYmplY3RzIG11c3QgaGF2ZSBhIFtTeW1ib2wuaXRlcmF0b3JdKCkgbWV0aG9kLlwiKTtcbn1cblxubW9kdWxlLmV4cG9ydHMgPSBfbm9uSXRlcmFibGVSZXN0O1xubW9kdWxlLmV4cG9ydHNbXCJkZWZhdWx0XCJdID0gbW9kdWxlLmV4cG9ydHMsIG1vZHVsZS5leHBvcnRzLl9fZXNNb2R1bGUgPSB0cnVlOyIsInZhciBhcnJheVdpdGhIb2xlcyA9IHJlcXVpcmUoXCIuL2FycmF5V2l0aEhvbGVzLmpzXCIpO1xuXG52YXIgaXRlcmFibGVUb0FycmF5TGltaXQgPSByZXF1aXJlKFwiLi9pdGVyYWJsZVRvQXJyYXlMaW1pdC5qc1wiKTtcblxudmFyIHVuc3VwcG9ydGVkSXRlcmFibGVUb0FycmF5ID0gcmVxdWlyZShcIi4vdW5zdXBwb3J0ZWRJdGVyYWJsZVRvQXJyYXkuanNcIik7XG5cbnZhciBub25JdGVyYWJsZVJlc3QgPSByZXF1aXJlKFwiLi9ub25JdGVyYWJsZVJlc3QuanNcIik7XG5cbmZ1bmN0aW9uIF9zbGljZWRUb0FycmF5KGFyciwgaSkge1xuICByZXR1cm4gYXJyYXlXaXRoSG9sZXMoYXJyKSB8fCBpdGVyYWJsZVRvQXJyYXlMaW1pdChhcnIsIGkpIHx8IHVuc3VwcG9ydGVkSXRlcmFibGVUb0FycmF5KGFyciwgaSkgfHwgbm9uSXRlcmFibGVSZXN0KCk7XG59XG5cbm1vZHVsZS5leHBvcnRzID0gX3NsaWNlZFRvQXJyYXk7XG5tb2R1bGUuZXhwb3J0c1tcImRlZmF1bHRcIl0gPSBtb2R1bGUuZXhwb3J0cywgbW9kdWxlLmV4cG9ydHMuX19lc01vZHVsZSA9IHRydWU7IiwiLy8gVE9ETzogb25jZSB3ZSd2ZSB1cGRhdGVkIGFsbCBvdXIgb2xkICdjaGFuZ2Vsb2cuanNvbicgZm9ybWF0cywgd2UgY2FuIGRyb3AgdGhpcy4gVGhlcmUgYXJlIG5vIGV4YW1wbGVzICdpbiB0aGUgd2lsZCcgdGhhdCB3ZSBuZWVkIHRvIHdvcnJ5IGFib3V0LlxuXG5pbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcbmltcG9ydCB7IHJlcXVpcmVFbnYsIHNhdmVDaGFuZ2Vsb2cgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcblxuY29uc3QgcmVhZE9sZENoYW5nZWxvZyA9ICgpID0+IHtcbiAgY29uc3QgY2xQYXRoID0gcmVxdWlyZUVudignQ0hBTkdFTE9HX0ZJTEUnKVxuICBjb25zdCBvbGRDbFBhdGggPSBgJHtjbFBhdGguc3Vic3RyaW5nKDAsIGNsUGF0aC5sZW5ndGggLSA1KX0uanNvbmBcblxuICBjb25zdCBvbGRDbENvbnRlbnRzID0gZnMucmVhZEZpbGVTeW5jKG9sZENsUGF0aClcbiAgY29uc3Qgb2xkQ2wgPSBKU09OLnBhcnNlKG9sZENsQ29udGVudHMpXG5cbiAgcmV0dXJuIG9sZENsXG59XG5cbmNvbnN0IGNvbnZlcnRGb3JtYXQgPSAoY2hhbmdlbG9nKSA9PiB7XG4gIGNoYW5nZWxvZy5yZXZlcnNlKCkgLy8gaW4tcGxhY2UgbW9kaWZpY2F0aW9uXG4gIGZvciAoY29uc3QgZW50cnkgb2YgY2hhbmdlbG9nKSB7XG4gICAgY29uc3QgbmV3U3RhcnQgPSBuZXcgRGF0ZSgpXG4gICAgbmV3U3RhcnQuc2V0VGltZSgwKVxuICAgIC8vIG9sZCBmb3JtYXQ6IFVUQzp5eXl5LW1tLWRkLUhITU0gWlxuICAgIGNvbnN0IFt5ZWFyLCBtb250aCwgZGF0ZSwgdGltZV0gPSBlbnRyeS5zdGFydFRpbWVzdGFtcExvY2FsLnNwbGl0KCcgJylbMF0uc3BsaXQoJy0nKVxuICAgIGNvbnN0IGhvdXIgPSB0aW1lLnN1YnN0cmluZygwLCAyKVxuICAgIGNvbnN0IG1pbnV0ZXMgPSB0aW1lLnN1YnN0cmluZygyKVxuXG4gICAgbmV3U3RhcnQuc2V0VVRDRnVsbFllYXIoeWVhcilcbiAgICBuZXdTdGFydC5zZXRVVENNb250aChtb250aCAtIDEpXG4gICAgbmV3U3RhcnQuc2V0VVRDRGF0ZShkYXRlKVxuICAgIG5ld1N0YXJ0LnNldFVUQ0hvdXJzKGhvdXIpXG4gICAgbmV3U3RhcnQuc2V0VVRDTWludXRlcyhtaW51dGVzKVxuXG4gICAgZW50cnkuc3RhcnRUaW1lc3RhbXAgPSBuZXdTdGFydC50b0lTT1N0cmluZygpXG4gICAgZGVsZXRlIGVudHJ5LnN0YXJ0VGltZXN0YW1wTG9jYWxcblxuICAgIGVudHJ5LnN0YXJ0RXBvY2hNaWxsaXMgPSBuZXdTdGFydC5nZXRUaW1lKClcblxuICAgIGVudHJ5LmNoYW5nZU5vdGVzID0gW2VudHJ5LmRlc2NyaXB0aW9uXVxuICAgIGRlbGV0ZSBlbnRyeS5kZXNjcmlwdGlvblxuXG4gICAgZW50cnkuc2VjdXJpdHlOb3RlcyA9IFtdXG4gICAgZW50cnkuZHJwQmNwTm90ZXMgPSBbXVxuICAgIGVudHJ5LmJhY2tvdXROb3RlcyA9IFtdXG4gIH1cblxuICByZXR1cm4gY2hhbmdlbG9nXG59XG5cbmNvbnN0IHVwZGF0ZUZpbGVGb3JtYXQgPSAoKSA9PiB7XG4gIGNvbnN0IG9sZENsID0gcmVhZE9sZENoYW5nZWxvZygpXG4gIGNvbnN0IGNoYW5nZWxvZyA9IGNvbnZlcnRGb3JtYXQob2xkQ2wpXG4gIHNhdmVDaGFuZ2Vsb2coY2hhbmdlbG9nKVxufVxuXG5leHBvcnQgeyBjb252ZXJ0Rm9ybWF0LCB1cGRhdGVGaWxlRm9ybWF0IH1cbiIsImltcG9ydCB7IGFkZEVudHJ5IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnknXG5pbXBvcnQgeyBmaW5hbGl6ZUNoYW5nZWxvZyB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1hY3Rpb24tZmluYWxpemUtZW50cnknXG5pbXBvcnQgeyBwcmludEVudHJpZXMgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctYWN0aW9uLXByaW50LWVudHJpZXMnXG5pbXBvcnQgeyB1cGRhdGVGaWxlRm9ybWF0IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi11cGRhdGUtZm9ybWF0J1xuXG4vLyBTZXR1cCB2YWxpZCBhY3Rpb25zXG5jb25zdCBBRERfRU5UUlkgPSAnYWRkLWVudHJ5J1xuY29uc3QgRklOQUxJWkVfRU5UUlkgPSAnZmluYWxpemUtZW50cnknXG5jb25zdCBQUklOVF9FTlRSSUVTID0gJ3ByaW50LWVudHJpZXMnXG5jb25zdCBVUERBVEVfRk9STUFUID0gJ3VwZGF0ZS1mb3JtYXQnXG5jb25zdCB2YWxpZEFjdGlvbnMgPSBbQUREX0VOVFJZLCBGSU5BTElaRV9FTlRSWSwgUFJJTlRfRU5UUklFUywgVVBEQVRFX0ZPUk1BVF1cblxuY29uc3QgZGV0ZXJtaW5lQWN0aW9uID0gKCkgPT4ge1xuICBjb25zdCBhcmdzID0gcHJvY2Vzcy5hcmd2LnNsaWNlKDIpXG5cbiAgaWYgKGFyZ3MubGVuZ3RoID09PSAwKSB7IC8vIHx8IGFyZ3MubGVuZ3RoID4gMSkgeyBUT0RPOiB3ZSBkbyBuZWVkIGFyZ3MgZm9yICdwcmludC1jaGFuZ2Vsb2cnLi4uXG4gICAgdGhyb3cgbmV3IEVycm9yKCdVbmV4cGVjdGVkIGFyZ3VtZW50IGNvdW50LiBQbGVhc2UgcHJvdmlkZSBleGFjdGx5IG9uZSBhY3Rpb24gYXJndW1lbnQuJylcbiAgfVxuXG4gIGNvbnN0IGFjdGlvbiA9IGFyZ3NbMF1cbiAgaWYgKHZhbGlkQWN0aW9ucy5pbmRleE9mKGFjdGlvbikgPT09IC0xKSB7XG4gICAgdGhyb3cgbmV3IEVycm9yKGBJbnZhbGlkIGFjdGlvbjogJHthY3Rpb259YClcbiAgfVxuXG4gIHN3aXRjaCAoYWN0aW9uKSB7XG4gIGNhc2UgQUREX0VOVFJZOlxuICAgIHJldHVybiBhZGRFbnRyeVxuICBjYXNlIEZJTkFMSVpFX0VOVFJZOlxuICAgIHJldHVybiBmaW5hbGl6ZUNoYW5nZWxvZ1xuICBjYXNlIFBSSU5UX0VOVFJJRVM6XG4gICAgcmV0dXJuICgpID0+IHByaW50RW50cmllcyhKU09OLnBhcnNlKGFyZ3NbMV0pLCBuZXcgRGF0ZShhcmdzWzJdKSlcbiAgY2FzZSBVUERBVEVfRk9STUFUOlxuICAgIHJldHVybiB1cGRhdGVGaWxlRm9ybWF0XG4gIGRlZmF1bHQ6XG4gICAgdGhyb3cgbmV3IEVycm9yKGBDYW5ub3QgcHJvY2VzcyB1bmtvd24gYWN0aW9uOiAke2FjdGlvbn1gKVxuICB9XG59XG5cbmNvbnN0IGV4ZWN1dGUgPSAoKSA9PiB7XG4gIGRldGVybWluZUFjdGlvbigpLmNhbGwoKVxufVxuXG5leHBvcnQge1xuICBkZXRlcm1pbmVBY3Rpb24sXG4gIGV4ZWN1dGUsXG4gIHZhbGlkQWN0aW9uc1xufVxuIiwiaW1wb3J0IHsgZXhlY3V0ZSB9IGZyb20gJy4vbGliLWNoYW5nZWxvZy1ydW5uZXInXG5cbmV4ZWN1dGUoKVxuIl0sIm5hbWVzIjpbInJlYWRDaGFuZ2Vsb2ciLCJjbFBhdGhpc2giLCJyZXF1aXJlRW52IiwiY2xQYXRoIiwiY2hhbmdlbG9nQ29udGVudHMiLCJmcyIsInJlYWRGaWxlU3luYyIsImNoYW5nZWxvZyIsIllBTUwiLCJwYXJzZSIsImtleSIsInByb2Nlc3MiLCJlbnYiLCJFcnJvciIsInNhdmVDaGFuZ2Vsb2ciLCJzdHJpbmdpZnkiLCJ3cml0ZUZpbGVTeW5jIiwiY3JlYXRlTmV3RW50cnkiLCJub3ciLCJEYXRlIiwic3RhcnRUaW1lc3RhbXAiLCJkYXRlRm9ybWF0Iiwic3RhcnRFcG9jaE1pbGxpcyIsImdldFRpbWUiLCJpc3N1ZXMiLCJzcGxpdCIsImludm9sdmVkUHJvamVjdHMiLCJuZXdFbnRyeSIsImJyYW5jaCIsImJyYW5jaEZyb20iLCJ3b3JrSW5pdGlhdG9yIiwiYnJhbmNoSW5pdGlhdG9yIiwiY2hhbmdlTm90ZXMiLCJzZWN1cml0eU5vdGVzIiwiZHJwQmNwTm90ZXMiLCJiYWNrb3V0Tm90ZXMiLCJwdXNoIiwiYWRkRW50cnkiLCJ1bmRlZmluZWQiLCJyZXF1aXJlJCQwIiwiZmluYWxpemVDdXJyZW50RW50cnkiLCJjdXJyZW50RW50cnkiLCJnaXRPcHRpb25zIiwiYmFzZURpciIsImN3ZCIsImJpbmFyeSIsIm1heENvbmN1cnJlbnRQcm9jZXNzZXMiLCJnaXQiLCJzaW1wbGVHaXQiLCJyYXciLCJyZXN1bHRzIiwiY29udHJpYnV0b3JzIiwibWFwIiwibCIsInJlcGxhY2UiLCJmaWx0ZXIiLCJsZW5ndGgiLCJmaW5hbGl6ZUNoYW5nZWxvZyIsInByaW50RW50cmllcyIsImhvdGZpeGVzIiwibGFzdFJlbGVhc2VEYXRlIiwicGFja2FnZUNvbnRlbnRzIiwicGFja2FnZURhdGEiLCJKU09OIiwiY2hhbmdlRW50cmllcyIsInIiLCJ0aW1lIiwibm90ZXMiLCJhdXRob3IiLCJjb25jYXQiLCJkYXRlIiwibWVzc2FnZSIsImVtYWlsIiwiaXNIb3RmaXgiLCJzb3J0IiwiYSIsImIiLCJlbnRyeSIsImF0dHJpYiIsInRvSVNPU3RyaW5nIiwiY29uc29sZSIsImxvZyIsIm5vdGUiLCJsaXEiLCJjb250cmFjdHMiLCJzZWN1cmUiLCJqb2luIiwicmVhZE9sZENoYW5nZWxvZyIsIm9sZENsUGF0aCIsInN1YnN0cmluZyIsIm9sZENsQ29udGVudHMiLCJvbGRDbCIsImNvbnZlcnRGb3JtYXQiLCJyZXZlcnNlIiwibmV3U3RhcnQiLCJzZXRUaW1lIiwic3RhcnRUaW1lc3RhbXBMb2NhbCIsInllYXIiLCJtb250aCIsImhvdXIiLCJtaW51dGVzIiwic2V0VVRDRnVsbFllYXIiLCJzZXRVVENNb250aCIsInNldFVUQ0RhdGUiLCJzZXRVVENIb3VycyIsInNldFVUQ01pbnV0ZXMiLCJkZXNjcmlwdGlvbiIsInVwZGF0ZUZpbGVGb3JtYXQiLCJBRERfRU5UUlkiLCJGSU5BTElaRV9FTlRSWSIsIlBSSU5UX0VOVFJJRVMiLCJVUERBVEVfRk9STUFUIiwidmFsaWRBY3Rpb25zIiwiZGV0ZXJtaW5lQWN0aW9uIiwiYXJncyIsImFyZ3YiLCJzbGljZSIsImFjdGlvbiIsImluZGV4T2YiLCJleGVjdXRlIiwiY2FsbCJdLCJtYXBwaW5ncyI6Ijs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUdBLElBQU1BLGFBQWEsR0FBRyxTQUFoQkEsYUFBZ0IsR0FBTTtBQUMxQixNQUFNQyxTQUFTLEdBQUdDLFVBQVUsQ0FBQyxnQkFBRCxDQUE1QjtBQUNBLE1BQU1DLE1BQU0sR0FBR0YsU0FBUyxLQUFLLEdBQWQsR0FBb0IsQ0FBcEIsR0FBd0JBLFNBQXZDO0FBRUEsTUFBTUcsaUJBQWlCLEdBQUdDLGFBQUUsQ0FBQ0MsWUFBSCxDQUFnQkgsTUFBaEIsRUFBd0IsTUFBeEIsQ0FBMUIsQ0FKMEI7O0FBSzFCLE1BQU1JLFNBQVMsR0FBR0Msd0JBQUksQ0FBQ0MsS0FBTCxDQUFXTCxpQkFBWCxDQUFsQjtBQUVBLFNBQU9HLFNBQVA7QUFDRCxDQVJEOztBQVVBLElBQU1MLFVBQVUsR0FBRyxTQUFiQSxVQUFhLENBQUNRLEdBQUQsRUFBUztBQUMxQixTQUFPQyxPQUFPLENBQUNDLEdBQVIsQ0FBWUYsR0FBWjtBQUFBO0FBQUEsSUFBMEIsSUFBSUcsS0FBSix3REFBMERILEdBQTFELEVBQTFCLENBQVA7QUFDRCxDQUZEOztBQUlBLElBQU1JLGFBQWEsR0FBRyxTQUFoQkEsYUFBZ0IsQ0FBQ1AsU0FBRCxFQUFlO0FBQ25DLE1BQU1KLE1BQU0sR0FBR0QsVUFBVSxDQUFDLGdCQUFELENBQXpCO0FBRUEsTUFBTUUsaUJBQWlCLEdBQUdJLHdCQUFJLENBQUNPLFNBQUwsQ0FBZVIsU0FBZixDQUExQjtBQUNBRixFQUFBQSxhQUFFLENBQUNXLGFBQUgsQ0FBaUJiLE1BQWpCLEVBQXlCQyxpQkFBekI7QUFDRCxDQUxEOztBQ2JBLElBQU1hLGNBQWMsR0FBRyxTQUFqQkEsY0FBaUIsQ0FBQ1YsU0FBRCxFQUFlO0FBQ3BDO0FBQ0EsTUFBTVcsR0FBRyxHQUFHLElBQUlDLElBQUosRUFBWjtBQUNBLE1BQU1D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
