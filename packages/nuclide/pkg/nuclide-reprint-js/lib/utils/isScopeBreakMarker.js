function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

/*
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

var _constantsMarkers2;

function _constantsMarkers() {
  return _constantsMarkers2 = _interopRequireDefault(require('../constants/markers'));
}

var SCOPE_BREAK_MARKERS = new Set([(_constantsMarkers2 || _constantsMarkers()).default.scopeBreak, (_constantsMarkers2 || _constantsMarkers()).default.scopeSpaceBreak]);

function isScopeBreakMarker(marker) {
  return SCOPE_BREAK_MARKERS.has(marker);
}

module.exports = isScopeBreakMarker;