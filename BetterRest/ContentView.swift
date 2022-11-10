//
//  ContentView.swift
//  BetterRest
//
//  Created by john martin on 9/16/22.
//

import SwiftUI
import CoreML

let CIRCLE_RADIUS = 210.0

struct ContentView: View {
    
    static var defaultWakeUpTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date.now
    }
    
    @State private var sleepAmount = 8.0
    @State private var wakeUp = defaultWakeUpTime
    @State private var coffeeCups = 1
    @State private var prediction: Date? = nil
    @State private var predictionComplete = false
    @State private var calculateAnimation = 1.0
    @State private var showCalculation = false
    
    var body: some View {
        
        var predictionText = "???"
        
        if predictionComplete {
            if let prediction = prediction {
                predictionText = "\(prediction.formatted(.dateTime.hour().minute()))"
            }
        }
                
        return NavigationView {
            
            ZStack (alignment: .bottom){
                                
                ZStack{
                    
                    RadialGradient(stops: [
                        .init(color: Color.purple.opacity(1.0), location: 0.3),
                        .init(color: Color.purple.opacity(0.55), location: 0.3),
                        .init(color: Color.purple.opacity(0.55), location: 0.3),
                        .init(color: Color.purple.opacity(0.55), location: 0.5),
                        .init(color: Color.purple.opacity(0.25), location: 0.5),
                        .init(color: Color.purple.opacity(0.25), location: 0.7),
                        .init(color: .white, location: 0.7)
                    ], center: .center, startRadius: CIRCLE_RADIUS * 0.5, endRadius: CIRCLE_RADIUS)
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Text("Bedtime")
                            .font(.system(size: 28))
                        
                        Text(predictionText)
                            .scaleEffect(1) // https://developer.apple.com/forums/thread/672228
                            .font(.system(size: 36))
                    }
                    .foregroundColor(.white)
                    
                }
                .frame(maxWidth: .infinity, maxHeight: CIRCLE_RADIUS * 2)
                .offset(y: showCalculation ? 0 : 800)
                .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: showCalculation)
                
                VStack {
                    
                    Spacer()
                    
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                        .onChange(of: sleepAmount, perform: { value in
                            showCalculation = false
                        })
                    
                    Stepper(coffeeCups == 1 ? "\(coffeeCups) cup of coffee" :  "\(coffeeCups) cups of coffee", value: $coffeeCups, in: 1...10, step: 1)
                        .onChange(of: coffeeCups, perform: { value in
                            showCalculation = false
                        })
                    
                    DatePicker("Enter Wakeup Time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .onChange(of: wakeUp, perform: { value in
                            showCalculation = false
                        })
                    
                    Spacer()
                                        
                    Button(action: {
                        calculateBedTime {
                            showCalculation = true
                        }
                    }) {

                        // NOTE: By putting the padding and everything on the text, the whole button is clickable
                        Text("GO")
                            .padding(40)
                            .background(Color(red: 255.0/255.0, green: 232.0/255.0, blue: 138.0/255.0))
                            .foregroundColor(.black)
                            .clipShape(Circle())
                            .contentShape(Circle())
                            .offset(y: showCalculation ? -200 : 0.0)
                            .scaleEffect(showCalculation ? 0.0 : 1.0)
                            .opacity(showCalculation ? 0 : 1.0)
                            .animation(.interpolatingSpring(stiffness: 100, damping: 12), value: showCalculation)
                    }
                    
                    Group {
                        Spacer()
                        Spacer()
                        Spacer()
                        Spacer()
                    }
                        
                }.padding()
                
            }
            .navigationTitle("Better Rest")
        }
    }
        
    func getWakeUpTime () -> Double {
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
        let hour = components.hour ?? 0
        let minutes = components.minute ?? 0
        
        return Double(hour * 60 * 60 + minutes * 60)
    }
    
    func calculateBedTime (action: () -> Void) {
                
        do {
            
            let config = MLModelConfiguration()
            let sleepCalculator = try SleepCalculatorModel(configuration: config)
            
            let input = SleepCalculatorModelInput(wake: getWakeUpTime(), estimatedSleep: sleepAmount, coffee: Double(coffeeCups))
            let output = try sleepCalculator.prediction(input: input)
                        
            prediction = wakeUp - output.actualSleep
            predictionComplete = true
                        
            action()
            
        } catch {
            fatalError("ml model failed")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
