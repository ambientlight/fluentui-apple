//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

#if canImport(AppKit)
	import AppKit
#endif

extension NSAppearance {
	var isDarkMode: Bool {
		return self.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
	}
}
