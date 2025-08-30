//
//  ContentView.swift
//  iCameraSimulation
//
//  Created by Jagadish Paul on 01/08/25.
//

import SwiftUI
import SwiftUI

struct CameraCaptureView: View {
    @StateObject private var cameraStream = CameraStreamReader()
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                if let image = cameraStream.latestImage {
                    Image(uiImage: image)
                        .resizable()
                        .scenePadding()
                        .frame(width: geometry.size.width)
                        .clipped()
                        .ignoresSafeArea(.all)
                } else {
                    Color.black.ignoresSafeArea()
                }
            }
            
//            VStack {
//                Spacer()
//                Button(action: {
//                    if let image = cameraStream.latestImage {
//                        onCapture(image)   // return captured image
//                        dismiss()          // close camera
//                    }
//                }) {
//                    Circle()
//                        .fill(Color.white)
//                        .frame(width: 70, height: 70)
//                        .overlay(
//                            Circle()
//                                .stroke(Color.gray, lineWidth: 2)
//                        )
//                        
//                }
//            }
        }
        .onAppear { cameraStream.startReading() }
        .onDisappear { cameraStream.stopReading() }
    }
}

struct ContentView: View {
    @State private var capturedImage: UIImage? = nil
    @State private var showCamera = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 700)
                    .cornerRadius(12)
                    .shadow(radius: 4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 700)
                    .overlay(Text("No Image Captured").foregroundColor(.gray))
                    .cornerRadius(12)
                   // .ignoresSafeArea()
            }
            
            Button(action: {
                showCamera = true
            }) {
                Text("Open Camera")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .padding()
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView() { image in
                self.capturedImage = image
            }
        }
    }
}
