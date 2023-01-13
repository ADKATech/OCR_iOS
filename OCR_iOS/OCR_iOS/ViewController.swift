//
//  ViewController.swift
//  OCR_iOS
//
//  Created by AmrAngry on 13/01/2023.
//  Copyright © 2020 ADKA Tech. All rights reserved.
//  www.adkatech.com
//
// https://betterprogramming.pub/ios-vision-text-document-scanner-effc0b7f4635


import UIKit
import VisionKit
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textView.isEditable = false
        setupVision()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(vc, animated: true)
    }
    
    func processImage(_ image: UIImage) {
       // let request = VNRecognizeTextRequest(completionHandler: nil)
       // request.recognitionLevel = .accurate // fast , but then we'd have to deal with less accuracy
       // request.recognitionLanguages = ["en_US"] //recognitionLanguages is an array of languages passed in a priority order from left to right
        
        imageView.image = image
        recognizeTextInImage(image)
    }
    
    private func setupVision() {
         textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
             guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
             
             var detectedText = ""
             for observation in observations {
                 guard let topCandidate = observation.topCandidates(1).first else { return }
                 print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
     
                 detectedText += topCandidate.string
                 detectedText += "\n"
                 
                // This gives us CGRect, which we can draw over the image.
                // topCandidate.boundingBox(for: topCandidate.string.startIndex..< topCandidate.string.endIndex)
                // Vision uses a different coordinate space than UIKit, hence, when drawing the bounding boxes, you need to flip the y-axis.
             }
             
             DispatchQueue.main.async {
                 self.textView.text = detectedText
                 self.textView.flashScrollIndicators()
             }
         }

         textRecognitionRequest.recognitionLevel = .accurate
     }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        textView.text = ""
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("Found \(scan.pageCount)")
        guard scan.pageCount >= 1 else {
                    controller.dismiss(animated: true)
                    return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
        
        processImage(newImage)
        
//        for i in 0 ..< scan.pageCount {
//            let img = scan.imageOfPage(at: i)
//            // ... your code here
//            print("Hello >> Scanned Image #\(i)")
//
//            processImage(img)
//        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
