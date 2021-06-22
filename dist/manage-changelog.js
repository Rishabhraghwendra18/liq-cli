'use strict';

var fs = require('fs');
var dateFormat = require('dateformat');

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

var fs__namespace = /*#__PURE__*/_interopNamespace(fs);
var dateFormat__default = /*#__PURE__*/_interopDefaultLegacy(dateFormat);

var ADD_ENTRY = "add-entry";
var validActions = [ADD_ENTRY];

var determineAction = function determineAction() {
  var args = process.argv.slice(2);

  if (args.length === 0 || args.length > 1) {
    throw new Error("Unexpected argument count. Please provide exactly one action argument.");
  }

  var action = args[0];

  if (validActions.indexOf(action) === -1) {
    throw new Error("Invalid action: ".concat(action));
  }

  return action;
};

var readChangelog = function readChangelog() {
  var clPath = requireEnv('CHANGELOG_FILE');
  var changelogContents = fs__namespace.readFileSync(clPath);
  var changelog = JSON.parse(changelogContents);
  return changelog;
};

var requireEnv = function requireEnv(key) {
  return process.env[key] || function (e) {
    throw e;
  }(new Error("Did not find required environment parameter: ".concat(key)));
};

var saveChangelog = function saveChangelog(changelog) {
  var clPath = requireEnv('CHANGELOG_FILE');
  var changelogContents = JSON.stringify(changelog, null, 2);
  fs__namespace.writeFileSync(clPath, changelogContents);
};

var addEntry = function addEntry(changelog) {
  // get the approx start time according to the local clock
  var startTimestampLocal = dateFormat__default['default'](new Date(), 'UTC:yyyy-mm-dd-HHMM Z'); // process the 'work unit' data

  var issues = requireEnv('WORK_ISSUES').split("\n");
  var involvedProjects = requireEnv('INVOLVED_PROJECTS').split("\n");
  var newEntry = {
    issues: issues,
    "branch": requireEnv('WORK_BRANCH'),
    startTimestampLocal: startTimestampLocal,
    "branchFrom": requireEnv('CURR_REPO_VERSION'),
    "description": requireEnv('WORK_DESC'),
    "workInitiator": requireEnv('WORK_INITIATOR'),
    "branchInitiator": requireEnv('CURR_USER'),
    involvedProjects: involvedProjects
  };
  changelog.push(newEntry);
  return newEntry;
};

var action = determineAction();
var changelog = readChangelog();

switch (action) {
  case ADD_ENTRY:
    addEntry(changelog);
    saveChangelog(changelog);
    break;

  default:
    throw new Error("Unexpected unknown action snuck through: ".concat(action));
}
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFuYWdlLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvY2hhbmdlbG9nL2xpYi1jaGFuZ2Vsb2ctY29yZS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnkuanMiLCIuLi9zcmMvbGlxL2FjdGlvbnMvd29yay9jaGFuZ2Vsb2cvaW5kZXguanMiXSwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0ICogYXMgZnMgZnJvbSAnZnMnXG5cbi8vIERlY2xhcmUgdmFsaWQgYWN0aW9uc1xuY29uc3QgQUREX0VOVFJZPVwiYWRkLWVudHJ5XCJcbmNvbnN0IHZhbGlkQWN0aW9ucyA9IFsgQUREX0VOVFJZIF1cblxuY29uc3QgZGV0ZXJtaW5lQWN0aW9uID0gKCkgPT4ge1xuICB2YXIgYXJncyA9IHByb2Nlc3MuYXJndi5zbGljZSgyKVxuXG4gIGlmIChhcmdzLmxlbmd0aCA9PT0gMCB8fCBhcmdzLmxlbmd0aCA+IDEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFVuZXhwZWN0ZWQgYXJndW1lbnQgY291bnQuIFBsZWFzZSBwcm92aWRlIGV4YWN0bHkgb25lIGFjdGlvbiBhcmd1bWVudC5gKVxuICB9XG5cbiAgY29uc3QgYWN0aW9uID0gYXJnc1swXVxuICBpZiAodmFsaWRBY3Rpb25zLmluZGV4T2YoYWN0aW9uKSA9PT0gLTEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYEludmFsaWQgYWN0aW9uOiAke2FjdGlvbn1gKVxuICB9XG5cbiAgcmV0dXJuIGFjdGlvblxufVxuXG5jb25zdCByZWFkQ2hhbmdlbG9nID0gKCkgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoY2xQYXRoKVxuICBjb25zdCBjaGFuZ2Vsb2cgPSBKU09OLnBhcnNlKGNoYW5nZWxvZ0NvbnRlbnRzKVxuXG4gIHJldHVybiBjaGFuZ2Vsb2dcbn1cblxuY29uc3QgcmVxdWlyZUVudiA9IChrZXkpID0+IHtcbiAgcmV0dXJuIHByb2Nlc3MuZW52W2tleV0gfHwgdGhyb3cgbmV3IEVycm9yKGBEaWQgbm90IGZpbmQgcmVxdWlyZWQgZW52aXJvbm1lbnQgcGFyYW1ldGVyOiAke2tleX1gKVxufVxuXG5jb25zdCBzYXZlQ2hhbmdlbG9nID0gKGNoYW5nZWxvZykgPT4ge1xuICBjb25zdCBjbFBhdGggPSByZXF1aXJlRW52KCdDSEFOR0VMT0dfRklMRScpXG5cbiAgY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBKU09OLnN0cmluZ2lmeShjaGFuZ2Vsb2csIG51bGwsIDIpXG4gIGZzLndyaXRlRmlsZVN5bmMoY2xQYXRoLCBjaGFuZ2Vsb2dDb250ZW50cylcbn1cblxuZXhwb3J0IHtcbiAgQUREX0VOVFJZLFxuICBkZXRlcm1pbmVBY3Rpb24sXG4gIHJlYWRDaGFuZ2Vsb2csXG4gIHJlcXVpcmVFbnYsXG4gIHNhdmVDaGFuZ2Vsb2dcbn1cbiIsImltcG9ydCBkYXRlRm9ybWF0IGZyb20gJ2RhdGVmb3JtYXQnXG5cbmltcG9ydCB7IHJlcXVpcmVFbnYgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcblxuY29uc3QgYWRkRW50cnkgPSAoY2hhbmdlbG9nKSA9PiB7XG4gIC8vIGdldCB0aGUgYXBwcm94IHN0YXJ0IHRpbWUgYWNjb3JkaW5nIHRvIHRoZSBsb2NhbCBjbG9ja1xuICBjb25zdCBzdGFydFRpbWVzdGFtcExvY2FsID0gZGF0ZUZvcm1hdChuZXcgRGF0ZSgpLCAnVVRDOnl5eXktbW0tZGQtSEhNTSBaJylcbiAgLy8gcHJvY2VzcyB0aGUgJ3dvcmsgdW5pdCcgZGF0YVxuICBjb25zdCBpc3N1ZXMgPSByZXF1aXJlRW52KCdXT1JLX0lTU1VFUycpLnNwbGl0KFwiXFxuXCIpXG4gIGNvbnN0IGludm9sdmVkUHJvamVjdHMgPSByZXF1aXJlRW52KCdJTlZPTFZFRF9QUk9KRUNUUycpLnNwbGl0KFwiXFxuXCIpXG5cbiAgY29uc3QgbmV3RW50cnkgPSB7XG4gICAgaXNzdWVzLFxuICAgIFwiYnJhbmNoXCI6IHJlcXVpcmVFbnYoJ1dPUktfQlJBTkNIJyksXG4gICAgc3RhcnRUaW1lc3RhbXBMb2NhbCxcbiAgICBcImJyYW5jaEZyb21cIjogcmVxdWlyZUVudignQ1VSUl9SRVBPX1ZFUlNJT04nKSxcbiAgICBcImRlc2NyaXB0aW9uXCI6IHJlcXVpcmVFbnYoJ1dPUktfREVTQycpLFxuICAgIFwid29ya0luaXRpYXRvclwiOiByZXF1aXJlRW52KCdXT1JLX0lOSVRJQVRPUicpLFxuICAgIFwiYnJhbmNoSW5pdGlhdG9yXCI6IHJlcXVpcmVFbnYoJ0NVUlJfVVNFUicpLFxuICAgIGludm9sdmVkUHJvamVjdHNcbiAgfVxuXG4gIGNoYW5nZWxvZy5wdXNoKG5ld0VudHJ5KVxuICByZXR1cm4gbmV3RW50cnlcbn1cblxuZXhwb3J0IHsgYWRkRW50cnkgfVxuIiwiaW1wb3J0IHsgQUREX0VOVFJZLCBkZXRlcm1pbmVBY3Rpb24sIHJlYWRDaGFuZ2Vsb2csIHNhdmVDaGFuZ2Vsb2cgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcbmltcG9ydCB7IGFkZEVudHJ5IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnknXG5cbi8vIE1haW4gc2VtYW50aWMgYm9keVxuY29uc3QgYWN0aW9uID0gZGV0ZXJtaW5lQWN0aW9uKClcbmNvbnN0IGNoYW5nZWxvZyA9IHJlYWRDaGFuZ2Vsb2coKVxuc3dpdGNoIChhY3Rpb24pIHtcbiAgY2FzZSBBRERfRU5UUlk6XG4gICAgYWRkRW50cnkoY2hhbmdlbG9nKVxuICAgIHNhdmVDaGFuZ2Vsb2coY2hhbmdlbG9nKTsgYnJlYWtcbiAgZGVmYXVsdDpcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFVuZXhwZWN0ZWQgdW5rbm93biBhY3Rpb24gc251Y2sgdGhyb3VnaDogJHthY3Rpb259YClcbn1cbiJdLCJuYW1lcyI6WyJBRERfRU5UUlkiLCJ2YWxpZEFjdGlvbnMiLCJkZXRlcm1pbmVBY3Rpb24iLCJhcmdzIiwicHJvY2VzcyIsImFyZ3YiLCJzbGljZSIsImxlbmd0aCIsIkVycm9yIiwiYWN0aW9uIiwiaW5kZXhPZiIsInJlYWRDaGFuZ2Vsb2ciLCJjbFBhdGgiLCJyZXF1aXJlRW52IiwiY2hhbmdlbG9nQ29udGVudHMiLCJmcyIsInJlYWRGaWxlU3luYyIsImNoYW5nZWxvZyIsIkpTT04iLCJwYXJzZSIsImtleSIsImVudiIsInNhdmVDaGFuZ2Vsb2ciLCJzdHJpbmdpZnkiLCJ3cml0ZUZpbGVTeW5jIiwiYWRkRW50cnkiLCJzdGFydFRpbWVzdGFtcExvY2FsIiwiZGF0ZUZvcm1hdCIsIkRhdGUiLCJpc3N1ZXMiLCJzcGxpdCIsImludm9sdmVkUHJvamVjdHMiLCJuZXdFbnRyeSIsInB1c2giXSwibWFwcGluZ3MiOiI7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUdBLElBQU1BLFNBQVMsR0FBQyxXQUFoQjtBQUNBLElBQU1DLFlBQVksR0FBRyxDQUFFRCxTQUFGLENBQXJCOztBQUVBLElBQU1FLGVBQWUsR0FBRyxTQUFsQkEsZUFBa0IsR0FBTTtBQUM1QixNQUFJQyxJQUFJLEdBQUdDLE9BQU8sQ0FBQ0MsSUFBUixDQUFhQyxLQUFiLENBQW1CLENBQW5CLENBQVg7O0FBRUEsTUFBSUgsSUFBSSxDQUFDSSxNQUFMLEtBQWdCLENBQWhCLElBQXFCSixJQUFJLENBQUNJLE1BQUwsR0FBYyxDQUF2QyxFQUEwQztBQUN4QyxVQUFNLElBQUlDLEtBQUosMEVBQU47QUFDRDs7QUFFRCxNQUFNQyxNQUFNLEdBQUdOLElBQUksQ0FBQyxDQUFELENBQW5COztBQUNBLE1BQUlGLFlBQVksQ0FBQ1MsT0FBYixDQUFxQkQsTUFBckIsTUFBaUMsQ0FBQyxDQUF0QyxFQUF5QztBQUN2QyxVQUFNLElBQUlELEtBQUosMkJBQTZCQyxNQUE3QixFQUFOO0FBQ0Q7O0FBRUQsU0FBT0EsTUFBUDtBQUNELENBYkQ7O0FBZUEsSUFBTUUsYUFBYSxHQUFHLFNBQWhCQSxhQUFnQixHQUFNO0FBQzFCLE1BQU1DLE1BQU0sR0FBR0MsVUFBVSxDQUFDLGdCQUFELENBQXpCO0FBRUEsTUFBTUMsaUJBQWlCLEdBQUdDLGFBQUUsQ0FBQ0MsWUFBSCxDQUFnQkosTUFBaEIsQ0FBMUI7QUFDQSxNQUFNSyxTQUFTLEdBQUdDLElBQUksQ0FBQ0MsS0FBTCxDQUFXTCxpQkFBWCxDQUFsQjtBQUVBLFNBQU9HLFNBQVA7QUFDRCxDQVBEOztBQVNBLElBQU1KLFVBQVUsR0FBRyxTQUFiQSxVQUFhLENBQUNPLEdBQUQsRUFBUztBQUMxQixTQUFPaEIsT0FBTyxDQUFDaUIsR0FBUixDQUFZRCxHQUFaO0FBQUE7QUFBQSxJQUEwQixJQUFJWixLQUFKLHdEQUEwRFksR0FBMUQsRUFBMUIsQ0FBUDtBQUNELENBRkQ7O0FBSUEsSUFBTUUsYUFBYSxHQUFHLFNBQWhCQSxhQUFnQixDQUFDTCxTQUFELEVBQWU7QUFDbkMsTUFBTUwsTUFBTSxHQUFHQyxVQUFVLENBQUMsZ0JBQUQsQ0FBekI7QUFFQSxNQUFNQyxpQkFBaUIsR0FBR0ksSUFBSSxDQUFDSyxTQUFMLENBQWVOLFNBQWYsRUFBMEIsSUFBMUIsRUFBZ0MsQ0FBaEMsQ0FBMUI7QUFDQUYsRUFBQUEsYUFBRSxDQUFDUyxhQUFILENBQWlCWixNQUFqQixFQUF5QkUsaUJBQXpCO0FBQ0QsQ0FMRDs7QUM5QkEsSUFBTVcsUUFBUSxHQUFHLFNBQVhBLFFBQVcsQ0FBQ1IsU0FBRCxFQUFlO0FBQzlCO0FBQ0EsTUFBTVMsbUJBQW1CLEdBQUdDLDhCQUFVLENBQUMsSUFBSUMsSUFBSixFQUFELEVBQWEsdUJBQWIsQ0FBdEMsQ0FGOEI7O0FBSTlCLE1BQU1DLE1BQU0sR0FBR2hCLFVBQVUsQ0FBQyxhQUFELENBQVYsQ0FBMEJpQixLQUExQixDQUFnQyxJQUFoQyxDQUFmO0FBQ0EsTUFBTUMsZ0JBQWdCLEdBQUdsQixVQUFVLENBQUMsbUJBQUQsQ0FBVixDQUFnQ2lCLEtBQWhDLENBQXNDLElBQXRDLENBQXpCO0FBRUEsTUFBTUUsUUFBUSxHQUFHO0FBQ2ZILElBQUFBLE1BQU0sRUFBTkEsTUFEZTtBQUVmLGNBQVVoQixVQUFVLENBQUMsYUFBRCxDQUZMO0FBR2ZhLElBQUFBLG1CQUFtQixFQUFuQkEsbUJBSGU7QUFJZixrQkFBY2IsVUFBVSxDQUFDLG1CQUFELENBSlQ7QUFLZixtQkFBZUEsVUFBVSxDQUFDLFdBQUQsQ0FMVjtBQU1mLHFCQUFpQkEsVUFBVSxDQUFDLGdCQUFELENBTlo7QUFPZix1QkFBbUJBLFVBQVUsQ0FBQyxXQUFELENBUGQ7QUFRZmtCLElBQUFBLGdCQUFnQixFQUFoQkE7QUFSZSxHQUFqQjtBQVdBZCxFQUFBQSxTQUFTLENBQUNnQixJQUFWLENBQWVELFFBQWY7QUFDQSxTQUFPQSxRQUFQO0FBQ0QsQ0FwQkQ7O0FDQUEsSUFBTXZCLE1BQU0sR0FBR1AsZUFBZSxFQUE5QjtBQUNBLElBQU1lLFNBQVMsR0FBR04sYUFBYSxFQUEvQjs7QUFDQSxRQUFRRixNQUFSO0FBQ0UsT0FBS1QsU0FBTDtBQUNFeUIsSUFBQUEsUUFBUSxDQUFDUixTQUFELENBQVI7QUFDQUssSUFBQUEsYUFBYSxDQUFDTCxTQUFELENBQWI7QUFBMEI7O0FBQzVCO0FBQ0UsVUFBTSxJQUFJVCxLQUFKLG9EQUFzREMsTUFBdEQsRUFBTjtBQUxKOzsifQ==
