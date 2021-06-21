'use strict';

var fs = require('fs');

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

var clPath = process.env.CHANGELOG_FILE;
var changelogContents = fs__namespace.readFileSync(clPath);
var changelog = JSON.parse(changelogContents);
console.log(changelog);
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoibGliLWNoYW5nZWxvZy5qcyIsInNvdXJjZXMiOlsiLi4vc3JjL2xpcS9hY3Rpb25zL3dvcmsvbGliLWNoYW5nZWxvZy5qcyJdLCJzb3VyY2VzQ29udGVudCI6WyJpbXBvcnQgKiBhcyBmcyBmcm9tICdmcydcblxuY29uc3QgY2xQYXRoID0gcHJvY2Vzcy5lbnYuQ0hBTkdFTE9HX0ZJTEVcblxuY29uc3QgY2hhbmdlbG9nQ29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoY2xQYXRoKVxuY29uc3QgY2hhbmdlbG9nID0gSlNPTi5wYXJzZShjaGFuZ2Vsb2dDb250ZW50cylcblxuY29uc29sZS5sb2coY2hhbmdlbG9nKVxuIl0sIm5hbWVzIjpbImNsUGF0aCIsInByb2Nlc3MiLCJlbnYiLCJDSEFOR0VMT0dfRklMRSIsImNoYW5nZWxvZ0NvbnRlbnRzIiwiZnMiLCJyZWFkRmlsZVN5bmMiLCJjaGFuZ2Vsb2ciLCJKU09OIiwicGFyc2UiLCJjb25zb2xlIiwibG9nIl0sIm1hcHBpbmdzIjoiOzs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUVBLElBQU1BLE1BQU0sR0FBR0MsT0FBTyxDQUFDQyxHQUFSLENBQVlDLGNBQTNCO0FBRUEsSUFBTUMsaUJBQWlCLEdBQUdDLGFBQUUsQ0FBQ0MsWUFBSCxDQUFnQk4sTUFBaEIsQ0FBMUI7QUFDQSxJQUFNTyxTQUFTLEdBQUdDLElBQUksQ0FBQ0MsS0FBTCxDQUFXTCxpQkFBWCxDQUFsQjtBQUVBTSxPQUFPLENBQUNDLEdBQVIsQ0FBWUosU0FBWjs7In0=
