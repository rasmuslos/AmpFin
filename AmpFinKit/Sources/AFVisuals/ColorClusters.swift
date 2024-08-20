//
//  File.swift
//
//
//  Created by Rasmus Krämer on 25.07.24.
//

import Foundation
import SwiftUI
import Accelerate
import AFFoundation

#if canImport(UIKit)
import UIKit
#endif

public extension AFVisuals {
    private static let tolerance = 10
    private static let maximumIterations = 50
    
    struct DominantColor: Identifiable, Hashable, Equatable {
        public let id = UUID()
        
        public let color: Color
        public let percentage: Int
        
        internal static var zero: DominantColor {
            return DominantColor(color: .clear, percentage: 0)
        }
    }
    
    /**
     This method extracts `k` dominant colors from the provided cover image using the Accelerate-Framework to run efficiently on all Apple devices.
     
     This code is taken from the Apple Accelerate sample project [Calculating the dominant colors in an image](https://developer.apple.com/documentation/accelerate/vimage/calculating_the_dominant_colors_in_an_image).
     Some adjustments have been made to convert everything to a static function and to support Swift Concurrency.
     */
    static func extractDominantColors(_ k: Int, cover: Cover) async throws -> [DominantColor] {
        let dimension = 256 // cover.size.dimensions
        let capacity = dimension * dimension
        
        var centroids = [Centroid]()
        var iterationCount = 0
        var converged = false
        
        // MARK: Allocate memory
        
        let centroidIndicesDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(scalarType: Int32.self, shape: .matrixRowMajor(dimension * dimension, 1))
        var rgbImageFormat = vImage_CGImageFormat(bitsPerComponent: 32, bitsPerPixel: 32 * 3, colorSpace: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: kCGBitmapByteOrder32Host.rawValue | CGBitmapInfo.floatComponents.rawValue | CGImageAlphaInfo.none.rawValue))!
        
        let redStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: capacity)
        let redBuffer = vImage.PixelBuffer<vImage.PlanarF>(data: redStorage.baseAddress!, width: dimension, height: dimension, byteCountPerRow: dimension * MemoryLayout<Float>.stride)
        
        let greenStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: capacity)
        let greenBuffer = vImage.PixelBuffer<vImage.PlanarF>(data: greenStorage.baseAddress!, width: dimension, height: dimension, byteCountPerRow: dimension * MemoryLayout<Float>.stride)
        
        let blueStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: capacity)
        let blueBuffer = vImage.PixelBuffer<vImage.PlanarF>(data: blueStorage.baseAddress!, width: dimension, height: dimension, byteCountPerRow: dimension * MemoryLayout<Float>.stride)
        
        let distances = UnsafeMutableBufferPointer<Float>.allocate(capacity: capacity * k)
        
        // MARK: Fetch image
        
        let url = cover.url
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let platformImage = UIImage(data: data), let image = platformImage.cgImage else {
            throw VisualError.fetchFailed
        }
        
        // MARK: Start
        
        let rgbSources: [vImage.PixelBuffer<vImage.PlanarF>] = try! vImage.PixelBuffer<vImage.InterleavedFx3>(cgImage: image, cgImageFormat: &rgbImageFormat).planarBuffers()
        
        rgbSources[0].scale(destination: redBuffer)
        rgbSources[1].scale(destination: greenBuffer)
        rgbSources[2].scale(destination: blueBuffer)
        
        // MARK: Initialize centroids
        
        let randomIndex = Int.random(in: 0 ..< dimension * dimension)
        centroids.append(Centroid(red: redStorage[randomIndex], green: greenStorage[randomIndex], blue: blueStorage[randomIndex]))
        
        let tmp = UnsafeMutableBufferPointer(start: distances.baseAddress!, count: capacity)
        for i in 1 ..< k {
            distanceSquared(x0: greenStorage.baseAddress!, x1: centroids[i - 1].green, y0: blueStorage.baseAddress!, y1: centroids[i - 1].blue, z0: redStorage.baseAddress!, z1: centroids[i - 1].red, n: greenStorage.count, result: tmp.baseAddress!)
            
            let randomIndex = weightedRandomIndex(tmp)
            
            centroids.append(Centroid(red: redStorage[randomIndex], green: greenStorage[randomIndex], blue: blueStorage[randomIndex]))
        }
        
        await Task.yield()
        
        // MARK: Run
        
        while !converged && iterationCount < maximumIterations {
            let pixelCounts = centroids.map { return $0.pixelCount }
            
            // MARK: Populate Distances
            
            for centroid in centroids.enumerated() {
                distanceSquared(x0: greenStorage.baseAddress!, x1: centroid.element.green, y0: blueStorage.baseAddress!, y1: centroid.element.blue, z0: redStorage.baseAddress!, z1: centroid.element.red, n: greenStorage.count, result: distances.baseAddress!.advanced(by: dimension * dimension * centroid.offset))
            }
            
            // MARK: Make Centroid Indices
            
            let distancesDescriptor = BNNSNDArrayDescriptor(data: distances, shape: .matrixRowMajor(dimension * dimension, k))!
            let reductionLayer = BNNS.ReductionLayer(function: .argMin, input: distancesDescriptor, output: centroidIndicesDescriptor, weights: nil)
            
            try reductionLayer?.apply(batchSize: 1, input: distancesDescriptor, output: centroidIndicesDescriptor)
            
            let centroidIndices = centroidIndicesDescriptor.makeArray(of: Int32.self)!
            
            for centroid in centroids.enumerated() {
                let indices = centroidIndices.enumerated().filter { $0.element == centroid.offset }.map { UInt($0.offset + 1) }
                
                centroids[centroid.offset].pixelCount = indices.count
                
                if !indices.isEmpty {
                    let gatheredRed = vDSP.gather(redStorage, indices: indices)
                    let gatheredGreen = vDSP.gather(greenStorage, indices: indices)
                    let gatheredBlue = vDSP.gather(blueStorage, indices: indices)
                    
                    centroids[centroid.offset].red = vDSP.mean(gatheredRed)
                    centroids[centroid.offset].green = vDSP.mean(gatheredGreen)
                    centroids[centroid.offset].blue = vDSP.mean(gatheredBlue)
                }
            }
            
            converged = pixelCounts.elementsEqual(centroids.map { return $0.pixelCount }) { a, b in abs(a - b) < tolerance }
            iterationCount += 1
            
            await Task.yield()
        }
        
        // MARK: Deallocate memory
        
        redStorage.deallocate()
        greenStorage.deallocate()
        blueStorage.deallocate()
        
        distances.deallocate()
        
        return centroids.map { centroid in
            let color = Color(red: Double(centroid.red), green: Double(centroid.green), blue: Double(centroid.blue))
            let percentage = Int(Float(centroid.pixelCount) / Float(dimension * dimension) * 100)
            
            return DominantColor(color: color, percentage: percentage)
        }
    }
}

private extension AFVisuals {
    static func subtract(a: UnsafePointer<Float>, b: Float, n: Int) -> [Float] {
        return [Float](unsafeUninitializedCapacity: n) { buffer, count in
            vDSP_vsub(a, 1, [b], 0, buffer.baseAddress!, 1, vDSP_Length(n))
            count = n
        }
    }
    static func distanceSquared(x0: UnsafePointer<Float>, x1: Float, y0: UnsafePointer<Float>, y1: Float, z0: UnsafePointer<Float>, z1: Float, n: Int, result: UnsafeMutablePointer<Float>) {
        var x = subtract(a: x0, b: x1, n: n)
        vDSP.square(x, result: &x)
        
        var y = subtract(a: y0, b: y1, n: n)
        vDSP.square(y, result: &y)
        
        var z = subtract(a: z0, b: z1, n: n)
        vDSP.square(z, result: &z)
        
        vDSP_vadd(x, 1, y, 1, result, 1, vDSP_Length(n))
        vDSP_vadd(result, 1, z, 1, result, 1, vDSP_Length(n))
    }
    
    static func weightedRandomIndex(_ weights: UnsafeMutableBufferPointer<Float>) -> Int {
        var outputDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(scalarType: Float.self, shape: .vector(1))
        var probabilities = BNNSNDArrayDescriptor(data: weights, shape: .vector(weights.count))!
        let randomGenerator = BNNSCreateRandomGenerator(BNNSRandomGeneratorMethodAES_CTR, nil)
        
        BNNSRandomFillCategoricalFloat(randomGenerator, &outputDescriptor, &probabilities, false)
        
        defer {
            BNNSDestroyRandomGenerator(randomGenerator)
            outputDescriptor.deallocate()
        }
        
        return Int(outputDescriptor.makeArray(of: Float.self)!.first!)
    }
}

private struct Centroid {
    var red: Float
    var green: Float
    var blue: Float
    
    var pixelCount: Int = 0
}
