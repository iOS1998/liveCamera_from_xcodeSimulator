//
//  CameraStreamReader.swift
//  iCameraSimulation
//
//  Created by Jagadish Paul on 01/08/25.
//

import Foundation
import SwiftUI


class CameraStreamReader: ObservableObject {
    @Published var latestImage: UIImage? = nil

    private var buffer: UnsafeMutableRawPointer?
    private var fd: Int32 = -1
    private var isCancelled = false

    private let width = 1280
    private let height = 720
    private let channels = 4
    private var frameSize: Int {
        return width * height * channels
    }

    // Set to the same path as the macOS shared memory file
    private let sharedMemoryPath = "/Users/jagadishpaul/Library/Containers/com.jagadish.ai.MacCameraStreamer/Data/camera_shared_buffer"


    func startReading() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.fd = open(self.sharedMemoryPath, O_RDONLY)
            guard self.fd != -1 else {
                print("Failed to open shared memory")
                return
            }

            self.buffer = mmap(nil, self.frameSize, PROT_READ, MAP_SHARED, self.fd, 0)
            guard self.buffer != MAP_FAILED else {
                print("mmap failed")
                close(self.fd)
                return
            }

            print("Shared memory reader started at \(self.sharedMemoryPath)")

            while !self.isCancelled {
                let data = Data(bytes: self.buffer!, count: self.frameSize)
                if let image = self.imageFromBGRAData(data) {
                    DispatchQueue.main.async {
                        self.latestImage = image
                    }
                }
                usleep(33_000) // ~30fps
            }

            self.cleanup()
        }
    }

    func stopReading() {
        isCancelled = true
    }

    private func cleanup() {
        if let buffer = buffer {
            munmap(buffer, frameSize)
            self.buffer = nil
        }
        if fd != -1 {
            close(fd)
            fd = -1
        }
    }

    func imageFromBGRAData(_ data: Data) -> UIImage? {
        let bytesPerRow = width * channels
        guard let providerRef = CGDataProvider(data: data as CFData) else { return nil }

        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        )

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else { return nil }

        return UIImage(cgImage: cgImage)
    }

}
