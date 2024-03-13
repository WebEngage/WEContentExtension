//
//  AnimatedGif.swift
//
//
//  Created by Shubham Naidu on 25/01/24.
//

import UIKit
import ImageIO

extension UIImage {

    private static func delayCentisecondsForImage(at index: Int, in source: CGImageSource) -> Int {
        var delayCentiseconds = 1
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any] {
            if let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                if let number = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber, number.doubleValue > 0 {
                    delayCentiseconds = Int(lrint(number.doubleValue * 100))
                } else if let number = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber, number.doubleValue > 0 {
                    delayCentiseconds = Int(lrint(number.doubleValue * 100))
                }
            }
        }
        return delayCentiseconds
    }

    private static func createImagesAndDelays(source: CGImageSource, count: Int) -> (images: [CGImage], delays: [Int]) {
        var images: [CGImage] = []
        var delays: [Int] = []

        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
                let delay = delayCentisecondsForImage(at: i, in: source)
                delays.append(delay)
            }
        }

        return (images, delays)
    }

    private static func sum(_ values: [Int]) -> Int {
        return values.reduce(0, +)
    }

    private static func pairGCD(a: Int, b: Int) -> Int {
        if a < b {
            return pairGCD(a: b, b: a)
        }

        var a = a
        var b = b

        while true {
            let r = a % b
            if r == 0 {
                return b
            }
            a = b
            b = r
        }
    }

    private static func vectorGCD(_ values: [Int]) -> Int {
        var gcd = values[0]

        for i in 1..<values.count {
            gcd = pairGCD(a: values[i], b: gcd)
        }

        return gcd
    }

    private static func frameArray(images: [CGImage], delays: [Int], totalDurationCentiseconds: Int) -> [UIImage] {
        let gcd = vectorGCD(delays)
        let frameCount = totalDurationCentiseconds / gcd

        var frames: [UIImage] = []

        for i in 0..<images.count {
            let frame = UIImage(cgImage: images[i])

            for _ in stride(from: delays[i] / gcd, to: 0, by: -1) {
                frames.append(frame)
            }
        }

        return frames
    }

    private static func animatedImageWithAnimatedGIFImageSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        let (images, delays) = createImagesAndDelays(source: source, count: count)
        let totalDurationCentiseconds = sum(delays)
        let frames = frameArray(images: images, delays: delays, totalDurationCentiseconds: totalDurationCentiseconds)


        return UIImage.animatedImage(with: frames, duration: TimeInterval(totalDurationCentiseconds) / 100.0)
    }

    private static func animatedImageWithAnimatedGIFReleasingImageSource(_ source: CGImageSource?) -> UIImage? {
        guard let source = source else {
            return nil
        }

        let animation = animatedImageWithAnimatedGIFImageSource(source)
        return animation
    }

    class func animatedImageWithAnimatedGIF(data: Data) -> UIImage? {
        return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithData(data as CFData, nil))
    }

    class func animatedImageWithAnimatedGIF(url: URL) -> UIImage? {
        return animatedImageWithAnimatedGIFReleasingImageSource(CGImageSourceCreateWithURL(url as CFURL, nil))
    }
}
