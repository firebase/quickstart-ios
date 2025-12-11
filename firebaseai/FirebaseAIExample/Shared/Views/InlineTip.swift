// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import TipKit

public struct InlineTip: Tip {
    private let _text: String
    private let _title: String
    private let _icon: Image

    public init(text: String, title: String = "Tip", icon: Image = Image(systemName: "info.circle")) {
        _text = text
        _title = title
        _icon = icon
    }

    public var title: Text {
        Text(_title)
    }

    public var message: Text? {
        Text(_text)
    }

    public var image: Image? {
        _icon
    }
}

#Preview {
    TipView(InlineTip(text: "Try asking the model to change the background color"))
    TipView(
        InlineTip(
            text: "You shouldn't do that.",
            title: "Warning",
            icon: Image(systemName: "exclamationmark.circle")
        )
    )
    TipView(
        InlineTip(
            text: "Oops, try again!",
            title: "Error",
            icon: Image(systemName: "x.circle")
        )
    )
}
