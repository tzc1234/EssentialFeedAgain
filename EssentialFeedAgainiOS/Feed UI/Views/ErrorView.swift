//
//  ErrorView.swift
//  EssentialFeedAgainiOS
//
//  Created by Tsz-Lung on 20/08/2024.
//

import SwiftUI

@Observable
final class ErrorViewStore {
    public var message: String?
    var onHide: (() -> Void)?
    
    func buttonTap() {
        message = nil
    }
}

struct ErrorView: View {
    var store: ErrorViewStore
    
    var body: some View {
        if let message = store.message {
            Button(action: {
                withAnimation(.linear(duration: 0.25)) {
                    store.buttonTap()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        store.onHide?()
                    }
                }
            }, label: {
                Text(message)
                    .font(.body)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .background(Color(uiColor: .errorBackground))
            })
        }
    }
}

extension UIColor {
    static var errorBackground: UIColor {
        UIColor(red: 0.99951404330000004, green: 0.41759261489999999, blue: 0.4154433012, alpha: 1)
    }
}

#Preview {
    let store = ErrorViewStore()
    store.message = "Error!"
    return ErrorView(store: store)
}
