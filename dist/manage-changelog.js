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
  var clPath = process.env.CHANGELOG_FILE;
  var changelogContents = fs__namespace.readFileSync(clPath);
  var changelog = JSON.parse(changelogContents);
  return changelog;
};

var requireEnv = function requireEnv(key) {
  return process.env[key] || function (e) {
    throw e;
  }(new Error("Did not find required environment parameter: ".concat(key)));
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
    break;

  default:
    throw new Error("Unexpected unknown action snuck through: ".concat(action));
}

console.log(changelog);
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibWFuYWdlLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvY2hhbmdlbG9nL2xpYi1jaGFuZ2Vsb2ctY29yZS5qcyIsIi4uL3NyYy9saXEvYWN0aW9ucy93b3JrL2NoYW5nZWxvZy9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnkuanMiLCIuLi9zcmMvbGlxL2FjdGlvbnMvd29yay9jaGFuZ2Vsb2cvaW5kZXguanMiXSwic291cmNlc0NvbnRlbnQiOlsiaW1wb3J0ICogYXMgZnMgZnJvbSAnZnMnXG5cbi8vIERlY2xhcmUgdmFsaWQgYWN0aW9uc1xuY29uc3QgQUREX0VOVFJZPVwiYWRkLWVudHJ5XCJcbmNvbnN0IHZhbGlkQWN0aW9ucyA9IFsgQUREX0VOVFJZIF1cblxuY29uc3QgZGV0ZXJtaW5lQWN0aW9uID0gKCkgPT4ge1xuICB2YXIgYXJncyA9IHByb2Nlc3MuYXJndi5zbGljZSgyKVxuXG4gIGlmIChhcmdzLmxlbmd0aCA9PT0gMCB8fCBhcmdzLmxlbmd0aCA+IDEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFVuZXhwZWN0ZWQgYXJndW1lbnQgY291bnQuIFBsZWFzZSBwcm92aWRlIGV4YWN0bHkgb25lIGFjdGlvbiBhcmd1bWVudC5gKVxuICB9XG5cbiAgY29uc3QgYWN0aW9uID0gYXJnc1swXVxuICBpZiAodmFsaWRBY3Rpb25zLmluZGV4T2YoYWN0aW9uKSA9PT0gLTEpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYEludmFsaWQgYWN0aW9uOiAke2FjdGlvbn1gKVxuICB9XG5cbiAgcmV0dXJuIGFjdGlvblxufVxuXG5jb25zdCByZWFkQ2hhbmdlbG9nID0gKCkgPT4ge1xuICBjb25zdCBjbFBhdGggPSBwcm9jZXNzLmVudi5DSEFOR0VMT0dfRklMRVxuXG4gIGNvbnN0IGNoYW5nZWxvZ0NvbnRlbnRzID0gZnMucmVhZEZpbGVTeW5jKGNsUGF0aClcbiAgY29uc3QgY2hhbmdlbG9nID0gSlNPTi5wYXJzZShjaGFuZ2Vsb2dDb250ZW50cylcblxuICByZXR1cm4gY2hhbmdlbG9nXG59XG5cbmNvbnN0IHJlcXVpcmVFbnYgPSAoa2V5KSA9PiB7XG4gIHJldHVybiBwcm9jZXNzLmVudltrZXldIHx8IHRocm93IG5ldyBFcnJvcihgRGlkIG5vdCBmaW5kIHJlcXVpcmVkIGVudmlyb25tZW50IHBhcmFtZXRlcjogJHtrZXl9YClcbn1cblxuZXhwb3J0IHtcbiAgQUREX0VOVFJZLFxuICBkZXRlcm1pbmVBY3Rpb24sXG4gIHJlYWRDaGFuZ2Vsb2csXG4gIHJlcXVpcmVFbnZcbn1cbiIsImltcG9ydCBkYXRlRm9ybWF0IGZyb20gJ2RhdGVmb3JtYXQnXG5cbmltcG9ydCB7IHJlcXVpcmVFbnYgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcblxuY29uc3QgYWRkRW50cnkgPSAoY2hhbmdlbG9nKSA9PiB7XG4gIC8vIGdldCB0aGUgYXBwcm94IHN0YXJ0IHRpbWUgYWNjb3JkaW5nIHRvIHRoZSBsb2NhbCBjbG9ja1xuICBjb25zdCBzdGFydFRpbWVzdGFtcExvY2FsID0gZGF0ZUZvcm1hdChuZXcgRGF0ZSgpLCAnVVRDOnl5eXktbW0tZGQtSEhNTSBaJylcbiAgLy8gcHJvY2VzcyB0aGUgJ3dvcmsgdW5pdCcgZGF0YVxuICBjb25zdCBpc3N1ZXMgPSByZXF1aXJlRW52KCdXT1JLX0lTU1VFUycpLnNwbGl0KFwiXFxuXCIpXG4gIGNvbnN0IGludm9sdmVkUHJvamVjdHMgPSByZXF1aXJlRW52KCdJTlZPTFZFRF9QUk9KRUNUUycpLnNwbGl0KFwiXFxuXCIpXG5cbiAgY29uc3QgbmV3RW50cnkgPSB7XG4gICAgaXNzdWVzLFxuICAgIFwiYnJhbmNoXCI6IHJlcXVpcmVFbnYoJ1dPUktfQlJBTkNIJyksXG4gICAgc3RhcnRUaW1lc3RhbXBMb2NhbCxcbiAgICBcImJyYW5jaEZyb21cIjogcmVxdWlyZUVudignQ1VSUl9SRVBPX1ZFUlNJT04nKSxcbiAgICBcImRlc2NyaXB0aW9uXCI6IHJlcXVpcmVFbnYoJ1dPUktfREVTQycpLFxuICAgIFwid29ya0luaXRpYXRvclwiOiByZXF1aXJlRW52KCdXT1JLX0lOSVRJQVRPUicpLFxuICAgIFwiYnJhbmNoSW5pdGlhdG9yXCI6IHJlcXVpcmVFbnYoJ0NVUlJfVVNFUicpLFxuICAgIGludm9sdmVkUHJvamVjdHNcbiAgfVxuXG4gIGNoYW5nZWxvZy5wdXNoKG5ld0VudHJ5KVxuICByZXR1cm4gbmV3RW50cnlcbn1cblxuZXhwb3J0IHsgYWRkRW50cnkgfVxuIiwiaW1wb3J0IHsgQUREX0VOVFJZLCBkZXRlcm1pbmVBY3Rpb24sIHJlYWRDaGFuZ2Vsb2cgfSBmcm9tICcuL2xpYi1jaGFuZ2Vsb2ctY29yZSdcbmltcG9ydCB7IGFkZEVudHJ5IH0gZnJvbSAnLi9saWItY2hhbmdlbG9nLWFjdGlvbi1hZGQtZW50cnknXG5cbi8vIE1haW4gc2VtYW50aWMgYm9keVxuY29uc3QgYWN0aW9uID0gZGV0ZXJtaW5lQWN0aW9uKClcbmNvbnN0IGNoYW5nZWxvZyA9IHJlYWRDaGFuZ2Vsb2coKVxuc3dpdGNoIChhY3Rpb24pIHtcbiAgY2FzZSBBRERfRU5UUlk6XG4gICAgYWRkRW50cnkoY2hhbmdlbG9nKTsgYnJlYWtcbiAgZGVmYXVsdDpcbiAgICB0aHJvdyBuZXcgRXJyb3IoYFVuZXhwZWN0ZWQgdW5rbm93biBhY3Rpb24gc251Y2sgdGhyb3VnaDogJHthY3Rpb259YClcbn1cblxuY29uc29sZS5sb2coY2hhbmdlbG9nKVxuIl0sIm5hbWVzIjpbIkFERF9FTlRSWSIsInZhbGlkQWN0aW9ucyIsImRldGVybWluZUFjdGlvbiIsImFyZ3MiLCJwcm9jZXNzIiwiYXJndiIsInNsaWNlIiwibGVuZ3RoIiwiRXJyb3IiLCJhY3Rpb24iLCJpbmRleE9mIiwicmVhZENoYW5nZWxvZyIsImNsUGF0aCIsImVudiIsIkNIQU5HRUxPR19GSUxFIiwiY2hhbmdlbG9nQ29udGVudHMiLCJmcyIsInJlYWRGaWxlU3luYyIsImNoYW5nZWxvZyIsIkpTT04iLCJwYXJzZSIsInJlcXVpcmVFbnYiLCJrZXkiLCJhZGRFbnRyeSIsInN0YXJ0VGltZXN0YW1wTG9jYWwiLCJkYXRlRm9ybWF0IiwiRGF0ZSIsImlzc3VlcyIsInNwbGl0IiwiaW52b2x2ZWRQcm9qZWN0cyIsIm5ld0VudHJ5IiwicHVzaCIsImNvbnNvbGUiLCJsb2ciXSwibWFwcGluZ3MiOiI7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUdBLElBQU1BLFNBQVMsR0FBQyxXQUFoQjtBQUNBLElBQU1DLFlBQVksR0FBRyxDQUFFRCxTQUFGLENBQXJCOztBQUVBLElBQU1FLGVBQWUsR0FBRyxTQUFsQkEsZUFBa0IsR0FBTTtBQUM1QixNQUFJQyxJQUFJLEdBQUdDLE9BQU8sQ0FBQ0MsSUFBUixDQUFhQyxLQUFiLENBQW1CLENBQW5CLENBQVg7O0FBRUEsTUFBSUgsSUFBSSxDQUFDSSxNQUFMLEtBQWdCLENBQWhCLElBQXFCSixJQUFJLENBQUNJLE1BQUwsR0FBYyxDQUF2QyxFQUEwQztBQUN4QyxVQUFNLElBQUlDLEtBQUosMEVBQU47QUFDRDs7QUFFRCxNQUFNQyxNQUFNLEdBQUdOLElBQUksQ0FBQyxDQUFELENBQW5COztBQUNBLE1BQUlGLFlBQVksQ0FBQ1MsT0FBYixDQUFxQkQsTUFBckIsTUFBaUMsQ0FBQyxDQUF0QyxFQUF5QztBQUN2QyxVQUFNLElBQUlELEtBQUosMkJBQTZCQyxNQUE3QixFQUFOO0FBQ0Q7O0FBRUQsU0FBT0EsTUFBUDtBQUNELENBYkQ7O0FBZUEsSUFBTUUsYUFBYSxHQUFHLFNBQWhCQSxhQUFnQixHQUFNO0FBQzFCLE1BQU1DLE1BQU0sR0FBR1IsT0FBTyxDQUFDUyxHQUFSLENBQVlDLGNBQTNCO0FBRUEsTUFBTUMsaUJBQWlCLEdBQUdDLGFBQUUsQ0FBQ0MsWUFBSCxDQUFnQkwsTUFBaEIsQ0FBMUI7QUFDQSxNQUFNTSxTQUFTLEdBQUdDLElBQUksQ0FBQ0MsS0FBTCxDQUFXTCxpQkFBWCxDQUFsQjtBQUVBLFNBQU9HLFNBQVA7QUFDRCxDQVBEOztBQVNBLElBQU1HLFVBQVUsR0FBRyxTQUFiQSxVQUFhLENBQUNDLEdBQUQsRUFBUztBQUMxQixTQUFPbEIsT0FBTyxDQUFDUyxHQUFSLENBQVlTLEdBQVo7QUFBQTtBQUFBLElBQTBCLElBQUlkLEtBQUosd0RBQTBEYyxHQUExRCxFQUExQixDQUFQO0FBQ0QsQ0FGRDs7QUMxQkEsSUFBTUMsUUFBUSxHQUFHLFNBQVhBLFFBQVcsQ0FBQ0wsU0FBRCxFQUFlO0FBQzlCO0FBQ0EsTUFBTU0sbUJBQW1CLEdBQUdDLDhCQUFVLENBQUMsSUFBSUMsSUFBSixFQUFELEVBQWEsdUJBQWIsQ0FBdEMsQ0FGOEI7O0FBSTlCLE1BQU1DLE1BQU0sR0FBR04sVUFBVSxDQUFDLGFBQUQsQ0FBVixDQUEwQk8sS0FBMUIsQ0FBZ0MsSUFBaEMsQ0FBZjtBQUNBLE1BQU1DLGdCQUFnQixHQUFHUixVQUFVLENBQUMsbUJBQUQsQ0FBVixDQUFnQ08sS0FBaEMsQ0FBc0MsSUFBdEMsQ0FBekI7QUFFQSxNQUFNRSxRQUFRLEdBQUc7QUFDZkgsSUFBQUEsTUFBTSxFQUFOQSxNQURlO0FBRWYsY0FBVU4sVUFBVSxDQUFDLGFBQUQsQ0FGTDtBQUdmRyxJQUFBQSxtQkFBbUIsRUFBbkJBLG1CQUhlO0FBSWYsa0JBQWNILFVBQVUsQ0FBQyxtQkFBRCxDQUpUO0FBS2YsbUJBQWVBLFVBQVUsQ0FBQyxXQUFELENBTFY7QUFNZixxQkFBaUJBLFVBQVUsQ0FBQyxnQkFBRCxDQU5aO0FBT2YsdUJBQW1CQSxVQUFVLENBQUMsV0FBRCxDQVBkO0FBUWZRLElBQUFBLGdCQUFnQixFQUFoQkE7QUFSZSxHQUFqQjtBQVdBWCxFQUFBQSxTQUFTLENBQUNhLElBQVYsQ0FBZUQsUUFBZjtBQUNBLFNBQU9BLFFBQVA7QUFDRCxDQXBCRDs7QUNBQSxJQUFNckIsTUFBTSxHQUFHUCxlQUFlLEVBQTlCO0FBQ0EsSUFBTWdCLFNBQVMsR0FBR1AsYUFBYSxFQUEvQjs7QUFDQSxRQUFRRixNQUFSO0FBQ0UsT0FBS1QsU0FBTDtBQUNFdUIsSUFBQUEsUUFBUSxDQUFDTCxTQUFELENBQVI7QUFBcUI7O0FBQ3ZCO0FBQ0UsVUFBTSxJQUFJVixLQUFKLG9EQUFzREMsTUFBdEQsRUFBTjtBQUpKOztBQU9BdUIsT0FBTyxDQUFDQyxHQUFSLENBQVlmLFNBQVo7OyJ9
