//
//  ViewController.swift
//  One Shot Learning
//
//  Created by Tomasz Baranowicz on 04/11/2019.
//  Copyright © 2019 Tomasz Baranowicz. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var photoImageView: UIImageView?
    
    var model: tivixObjectDetector!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        model = tivixObjectDetector()
    }

    @IBAction func takePhoto(sender: UIButton) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        present(vc, animated: true)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else {
            return
        }

        let inputSize = 416
        
        //scale image to 416x416
        UIGraphicsBeginImageContextWithOptions(CGSize(width: inputSize, height: inputSize), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: inputSize, height: inputSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //set preview
        self.photoImageView?.image = newImage
        
        
        //load to Core Video pixel buffer
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        
        //predict using model
        guard let prediction = try? model.prediction(image: pixelBuffer!, iouThreshold: 0.45, confidenceThreshold: 0.5) else {
            return
        }
        
        print(prediction.confidence)
        print(prediction.coordinates)
        print("-------------------")
    }
}
