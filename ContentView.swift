import SwiftUI
import Combine
import CoreMotion
import VisionKit

// A blueprint for a To-Do List Task
struct TaskItem: Identifiable {
    let id = UUID()
    var name : String
    var isCompleted: Bool = false
}

struct ContentView: View {
    
    func timeString(time: Int)-> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // --- APP MEMORY ---
    @State private var tips = 50 // Starting with 50 so they can test the pledge system!
    @State private var timeRemaining = 1500
    @State private var isTimerRunning = false
    @State private var selectedTime = 1500
    
    // 🌟 NEW: Gamification & Break Memory
    @State private var pledgeAmount = 0
    @State private var customMinutes = 10
    @State private var isBreakMode = false
    @State private var showingCustomTime = false
    
    // The Cafe Inventory
    @State private var ownsMatcha = false
    @State private var ownsTumbler = false
    @State private var ownsSteam = false
    @State private var ownsStrawberryLatte = false
    @State private var ownsBananaShake = false
    @State private var ownsLemonade = false
    @State private var ownsIcedTea = false
    @State private var ownsHotChocolate = false
    
    @State private var showingQuitAlert = false
    @State private var showingToDoSheet = false
    @State private var tasks: [TaskItem] = []
    
    @State private var pulseOpacity: Double = 0.0
    
    // Powers up the gyroscope engine
    @StateObject private var motion = MotionManager()
    
    @ScaledMetric var timerFontSize: CGFloat = 80
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // --- THE SMART DRINK MATH & LOGIC ---
    var fillPercentage: Double {
        return 1.0 - (Double(timeRemaining) / Double(selectedTime))
    }
    
    var liquidColor: Color {
        if isBreakMode { return Color.blue.opacity(0.6) } // Break water!
        if ownsHotChocolate { return Color.brown.opacity(0.9) }
        else if ownsIcedTea { return Color.orange.opacity(0.8) }
        else if ownsLemonade { return Color.yellow.opacity(0.8) }
        else if ownsBananaShake { return Color.yellow.opacity(0.4) }
        else if ownsStrawberryLatte { return Color.pink.opacity(0.8) }
        else if ownsTumbler { return Color.brown }
        else if ownsMatcha { return Color.green }
        else { return Color.cyan.opacity(0.7) }
    }
    
    var drinkEmoji: String {
        if isBreakMode { return "💧" }
        if ownsHotChocolate { return "☕️" }
        if ownsIcedTea { return "🧋" }
        if ownsLemonade { return "🍋" }
        if ownsBananaShake { return "🍌" }
        if ownsStrawberryLatte { return "🍓" }
        if ownsTumbler { return "🥤" }
        if ownsMatcha { return "🍵" }
        return "🥛"
    }
    
    var drinkName: String {
        if isBreakMode { return "Water Break" }
        if ownsHotChocolate { return "Hot Cocoa" }
        if ownsIcedTea { return "Iced Tea" }
        if ownsLemonade { return "Lemonade" }
        if ownsBananaShake { return "Banana Shake" }
        if ownsStrawberryLatte { return "Strawberry Latte" }
        if ownsTumbler { return "Coffee" }
        if ownsMatcha { return "Matcha" }
        return "Milk"
    }
        
    // --- APP SCREEN ---
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.1, green: 0.1, blue: 0.25), Color(red: 0.4, green: 0.25, blue: 0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                ).ignoresSafeArea()
                
                Color.white
                    .opacity(pulseOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                VStack(spacing: 30) {
                    Text(isBreakMode ? "Enjoy your break! 🧘‍♂️" : "Tips Earned: \(tips) 🪙")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    VStack {
                        ZStack(alignment: .bottom) {
                            Rectangle().fill(Color.white.opacity(0.5)).frame(width: 8, height: 140).offset(x: 15, y: -20).rotationEffect(.degrees(10), anchor: .bottom)
                            RoundedRectangle(cornerRadius: 10).fill(liquidColor).frame(width: 65, height: 95 * fillPercentage).animation(.linear(duration: 1.0), value: fillPercentage).padding(.bottom, 5)
                            RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.8), lineWidth: 4).frame(width: 75, height: 110).background(Color.white.opacity(0.1).cornerRadius(15))
                            
                            if isTimerRunning && differentiateWithoutColor {
                                Text(drinkName).font(.caption2).bold().foregroundColor(.white).offset(y: -45).shadow(radius: 2)
                            }
                            if isTimerRunning && ownsSteam && !isBreakMode {
                                SteamView().offset(y: -90)
                            }
                            Capsule().fill(Color.white.opacity(0.9)).frame(width: 85, height: 15).offset(y: -105)
                            if timeRemaining == 0 {
                                Text(drinkEmoji).font(.system(size: 60)).offset(y: -30)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Coffee Cup")
                    .accessibilityValue(timeRemaining == 0 ? "Drink is Ready" : "\(Int(fillPercentage * 100)) percent full")
                    .padding(.vertical, 40)
                    .padding(.horizontal, 80)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(35)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : motion.roll * 15), axis: (x: 0, y: 1, z: 0))
                    .rotation3DEffect(.degrees(reduceMotion ? 0 : motion.pitch * 15), axis: (x: -1, y: 0, z: 0))
                    .animation(.interactiveSpring(), value: motion.roll)
                    
                    Text(timeString(time: timeRemaining))
                        .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    
                    // 🌟 NEW: Custom Time & Pledge UI
                    if !isTimerRunning {
                        
                        // Time Selection Buttons
                        HStack(spacing: 10) {
                            Button("25m") { selectedTime = 1500; timeRemaining = 1500; showingCustomTime = false }
                                .padding(.horizontal, 15).padding(.vertical, 10).background(selectedTime == 1500 ? Color.orange : Color.white.opacity(0.2)).foregroundColor(.white).clipShape(Capsule())
                            
                            Button("45m") { selectedTime = 2700; timeRemaining = 2700; showingCustomTime = false }
                                .padding(.horizontal, 15).padding(.vertical, 10).background(selectedTime == 2700 ? Color.orange : Color.white.opacity(0.2)).foregroundColor(.white).clipShape(Capsule())
                            
                            Button("Custom") { showingCustomTime.toggle() }
                                .padding(.horizontal, 15).padding(.vertical, 10).background(showingCustomTime ? Color.orange : Color.white.opacity(0.2)).foregroundColor(.white).clipShape(Capsule())
                        }
                        
                        // Custom Time Stepper
                        if showingCustomTime {
                            Stepper("Time: \(customMinutes) min", value: $customMinutes, in: 1...120)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .onChange(of: customMinutes) {
                                    selectedTime = customMinutes * 60
                                    timeRemaining = customMinutes * 60
                                }
                        }
                        
                        // The Double-Or-Nothing Pledge
                        VStack(spacing: 5) {
                            Text("Double-or-Nothing Challenge!").font(.caption).bold().foregroundColor(.yellow)
                            Stepper("Pledge \(pledgeAmount) 🪙 to win \(pledgeAmount * 2) 🪙", value: $pledgeAmount, in: 0...tips, step: 5)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                        }
                        .padding(.top, 5)
                    }
                    
                    // --- SMART START/STOP BUTTON ---
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        if isTimerRunning {
                            showingQuitAlert = true
                        } else {
                            // 🌟 NEW: Start timer and deduct pledge
                            tips -= pledgeAmount
                            isTimerRunning = true
                        }
                    }) {
                        Text(isTimerRunning ? "Stop \(isBreakMode ? "Break" : "Brewing")" : "Brew & Study")
                            .font(.title3).bold()
                            .padding(.vertical, 15)
                            .padding(.horizontal, 40)
                            .background(isTimerRunning ? Color.red : Color.orange)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                }
            }
            .onReceive(timer) { _ in
                if isTimerRunning {
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        // TIMER HITS ZERO!
                        pulseOpacity = 0.8
                        withAnimation(.easeOut(duration: 1.5)){ pulseOpacity = 0.0 }
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        
                        if isBreakMode {
                            // Break is over, back to normal
                            isBreakMode = false
                            isTimerRunning = false
                            timeRemaining = selectedTime // Reset to their last picked study time
                            UIAccessibility.post(notification: .announcement, argument: "Break over! Ready to study.")
                        } else {
                            // Study is over, give rewards and start break!
                            tips += (pledgeAmount * 2) // PLEDGE WON!
                            pledgeAmount = 0
                            
                            // Standard completion tips
                            if selectedTime >= 3600 { tips += 75 }
                            else if selectedTime >= 2700 { tips += 50 }
                            else { tips += 25 }
                            
                            UIAccessibility.post(notification: .announcement, argument: "Study session complete! 5 minute break starting.")
                            
                            // Start 5-min Break Mode automatically
                            isBreakMode = true
                            selectedTime = 300
                            timeRemaining = 300
                            isTimerRunning = true
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showingToDoSheet = true }) {
                        Image(systemName: "checklist").font(.title2).foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ShopView(tips: $tips, ownsMatcha: $ownsMatcha, ownsTumbler: $ownsTumbler, ownsSteam: $ownsSteam, ownsStrawberryLatte: $ownsStrawberryLatte, ownsBananaShake: $ownsBananaShake, ownsLemonade: $ownsLemonade, ownsIcedTea: $ownsIcedTea, ownsHotChocolate: $ownsHotChocolate)){
                        Text("Supply Shop ☕️").bold().foregroundColor(.orange)
                    }
                }
            }
            .sheet(isPresented: $showingToDoSheet) {
                ToDoView(tips: $tips, tasks: $tasks)
            }
            .alert("Are you sure?", isPresented: $showingQuitAlert) {
                Button("Keep Going", role: .cancel) { }
                Button("Stop Early", role: .destructive) {
                    isTimerRunning = false
                    isBreakMode = false
                    pledgeAmount = 0 // PLEDGE LOST!
                    timeRemaining = selectedTime
                }
            } message: {
                Text(isBreakMode ? "End your break early?" : "The drink will be ruined and your pledged tips will be lost!")
            }
        }
    }
}

// --- TODO SCREEN ---
struct ToDoView: View {
    @Binding var tips: Int
    @Binding var tasks: [TaskItem]
    @State private var newTaskName = ""
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    TextField("What do you need to study?", text: $newTaskName)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                    
                    if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                        Button(action: { isShowingScanner = true }) {
                            Image(systemName: "text.viewfinder").font(.title2).foregroundColor(.white).padding(12).background(Color.blue).clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        if !newTaskName.isEmpty { tasks.append(TaskItem(name: newTaskName)); newTaskName = "" }
                    }) {
                        Text("Add").bold().padding(.horizontal, 20).padding(.vertical, 12).background(Color.orange).foregroundColor(.white).clipShape(Capsule())
                    }
                }
                .padding()
                
                List {
                    ForEach($tasks) { $task in
                        HStack {
                            Text(task.name).strikethrough(task.isCompleted).foregroundColor(task.isCompleted ? .gray : .primary)
                            Spacer()
                            Button(action: {
                                if !task.isCompleted { task.isCompleted = true; tips += 5; UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
                            }) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").foregroundColor(task.isCompleted ? .green : .gray).font(.title)
                            }
                            .accessibilityLabel(task.isCompleted ? "Completed": "Incomplete")
                            .accessibilityHint("Double tap to finish task and earn 5 tips")
                        }.padding(.vertical, 4)
                    }
                }.listStyle(.insetGrouped)
            }
            .navigationTitle("Study Tasks 📝")
            .sheet(isPresented: $isShowingScanner) {
                TextScannerView(scannedText: $newTaskName).ignoresSafeArea()
            }
        }
    }
}

// --- SHOP SCREEN ---
struct ShopView: View {
    
    @Binding var tips: Int
    @Binding var ownsMatcha: Bool
    @Binding var ownsTumbler: Bool
    @Binding var ownsSteam: Bool
    @Binding var ownsStrawberryLatte: Bool
    @Binding var ownsBananaShake: Bool
    @Binding var ownsLemonade: Bool
    @Binding var ownsIcedTea: Bool
    @Binding var ownsHotChocolate: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.25), Color(red: 0.4, green: 0.25, blue: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing:20) {
                    Text("Cafe Supply Shop ☕️").font(.largeTitle).bold().foregroundColor(.white).padding(.top)
                    Text("You have \(tips) Tips 🪙").font(.title2).foregroundColor(.white).padding(.bottom, 20)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsMatcha && tips >= 50 { tips -= 50; ownsMatcha = true }
                    }) { HStack { Text(" 🍵 Matcha Upgrade"); Spacer(); Text(ownsMatcha ? "Owned" : "50 🪙") }
                        .padding().background(ownsMatcha ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsMatcha)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsTumbler && tips >= 100 { tips -= 100; ownsTumbler = true }
                    }) { HStack { Text(" 🥤 Sleek Tumbler"); Spacer(); Text(ownsTumbler ? "Owned" : "100 🪙") }
                        .padding().background(ownsTumbler ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsTumbler)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsSteam && tips >= 150 { tips -= 150; ownsSteam = true }
                    }) { HStack { Text(" ♨️ Piping Hot Steam"); Spacer(); Text(ownsSteam ? "Owned" : "150 🪙") }
                        .padding().background(ownsSteam ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsSteam)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsStrawberryLatte && tips >= 200 { tips -= 200; ownsStrawberryLatte = true }
                    }) { HStack { Text(" 🍓 Strawberry Latte"); Spacer(); Text(ownsStrawberryLatte ? "Owned" : "200 🪙") }
                        .padding().background(ownsStrawberryLatte ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsStrawberryLatte)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsBananaShake && tips >= 250 { tips -= 250; ownsBananaShake = true }
                    }) { HStack { Text(" 🍌 Banana Shake"); Spacer(); Text(ownsBananaShake ? "Owned" : "250 🪙") }
                        .padding().background(ownsBananaShake ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsBananaShake)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsLemonade && tips >= 300 { tips -= 300; ownsLemonade = true }
                    }) { HStack { Text(" 🍋 Fresh Lemonade"); Spacer(); Text(ownsLemonade ? "Owned" : "300 🪙") }
                        .padding().background(ownsLemonade ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsLemonade)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsIcedTea && tips >= 350 { tips -= 350; ownsIcedTea = true }
                    }) { HStack { Text(" 🧋 Classic Iced Tea"); Spacer(); Text(ownsIcedTea ? "Owned" : "350 🪙") }
                        .padding().background(ownsIcedTea ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsIcedTea)
                    
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if !ownsHotChocolate && tips >= 400 { tips -= 400; ownsHotChocolate = true }
                    }) { HStack { Text(" ☕️ Rich Hot Chocolate"); Spacer(); Text(ownsHotChocolate ? "Owned" : "400 🪙") }
                        .padding().background(ownsHotChocolate ? Color.gray : Color.orange.opacity(0.9)).foregroundColor(.white).clipShape(Capsule())
                    }.padding(.horizontal).disabled(ownsHotChocolate)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// --- THE PHYSICS ENGINE ---
class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var pitch: Double = 0.0
    @Published var roll: Double = 0.0
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
                guard let motion = motion else { return }
                DispatchQueue.main.async { self.pitch = motion.attitude.pitch; self.roll = motion.attitude.roll }
            }
        }
    }
}

// --- THE STEAM ANIMATION ---
struct SteamView: View {
    @State private var steamRise: CGFloat = 0
    @State private var steamFade: Double = 0.8
    var body: some View {
        Image(systemName: "smoke.fill").font(.system(size:40)).foregroundColor(.white.opacity(0.5)).offset(y: steamRise).opacity(steamFade)
            .onAppear { withAnimation(.easeOut(duration: 2.5).repeatForever(autoreverses: false)){ steamRise = -60; steamFade = 0 } }
    }
}

// --- THE AI TEXT SCANNER ---
struct TextScannerView: UIViewControllerRepresentable {
    @Binding var scannedText: String
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.text()], qualityLevel: .balanced, recognizesMultipleItems: false, isHighFrameRateTrackingEnabled: false, isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: TextScannerView
        init(_ parent: TextScannerView) { self.parent = parent }
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .text(let text) = item {
                parent.scannedText = text.transcript
                parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    ContentView()
}

