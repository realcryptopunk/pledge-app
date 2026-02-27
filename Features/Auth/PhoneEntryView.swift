import SwiftUI

struct PhoneEntryView: View {
    @EnvironmentObject var appState: AppState
    @State private var phoneNumber = ""
    @State private var showOTP = false
    @FocusState private var isPhoneFocused: Bool
    
    private var formattedPhone: String {
        let digits = phoneNumber.filter { $0.isNumber }
        var result = ""
        for (index, char) in digits.enumerated() {
            if index == 0 { result += "(" }
            if index == 3 { result += ") " }
            if index == 6 { result += "-" }
            result += String(char)
        }
        return result
    }
    
    private var isValid: Bool {
        phoneNumber.filter { $0.isNumber }.count >= 10
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.pledgeBgAdaptive.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    
                    Text("Your phone number")
                        .pledgeHero(36)
                        .foregroundColor(.pledgeBlackAdaptive)
                    
                    Spacer().frame(height: 8)
                    
                    Text("We'll send you a verification code")
                        .pledgeBody()
                        .foregroundColor(.pledgeGray)
                    
                    Spacer().frame(height: 40)
                    
                    // Phone input
                    HStack(spacing: 12) {
                        // Country code pill
                        HStack(spacing: 4) {
                            Text("🇺🇸")
                            Text("+1")
                                .pledgeHeadline()
                                .foregroundColor(.pledgeBlackAdaptive)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Color.pledgeGrayUltraAdaptive)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
                        // Phone field
                        TextField("(555) 123-4567", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .pledgeHeadline()
                            .foregroundColor(.pledgeBlackAdaptive)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .background(Color.pledgeGrayUltraAdaptive)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isPhoneFocused ? Color.pledgeBlue : Color.clear, lineWidth: 2)
                            )
                            .focused($isPhoneFocused)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Continue button
                    Button {
                        PPHaptic.medium()
                        showOTP = true
                    } label: {
                        Text("Continue")
                    }
                    .buttonStyle(PrimaryCapsuleStyle(isEnabled: isValid))
                    .disabled(!isValid)
                    .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 8)
                    
                    Text("By continuing, you agree to our [Terms](https://pledge.app/terms) & [Privacy Policy](https://pledge.app/privacy)")
                        .pledgeCaption()
                        .foregroundColor(.pledgeGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
            }
            .onAppear { isPhoneFocused = true }
            .navigationDestination(isPresented: $showOTP) {
                OTPVerificationView()
            }
        }
    }
}

#Preview {
    PhoneEntryView()
        .environmentObject(AppState())
}
