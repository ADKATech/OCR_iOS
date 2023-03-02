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
    //put that request into an array, and set Vision off in a background queue to scan your image. For example, this uses the default .userInitiated background queue,
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
        //The Vision framework has built-in support for detecting text in images
        //Your request will be handed an array of observations that you need to safely typecast as VNRecognizedTextObservation,
        // then you can loop over each observation to pull out candidates for each one – various possible piece of text that Vision thinks it might have found.
         textRecognitionRequest = VNRecognizeTextRequest { request, error in
             guard let observations = request.results as? [VNRecognizedTextObservation] else {
                 //fatalError("Received invalid observations")
                 return
             }
             
             var detectedText = ""
             for observation in observations {
                //VNRecognizedTextObservation which itself has a number of candidates for us to investigate.
                //You can choose to receive up to 10 candidates for each piece of recognized text and they are sorted in decreasing confidence
                 guard let topCandidate = observation.topCandidates(1).first else {
                     print("No candidate")
                     continue
                     //return
                 }
                 print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                 print(topCandidate.boundingBox) //bounding box uses a normalized coordinate system with the origin in the bottom-left so you’ll need to convert it if you want it to play nicely with UIKit.
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
//by default the recognitionLevel property of your VNRecognizeTextRequest is set to .accurate, which means Vision does its best to figure out the most likely letters in the text
         textRecognitionRequest.recognitionLevel = .accurate
        //If you wanted to prioritize speed over accuracy – perhaps if you were scanning lots of image, or a live feed, you should change recognitionLevel to .fast, like this:
        
       // Second, you can set the customWords property of your request to be an array of unusual strings that your app is likely to come across – words that Vision might decide aren’t likely because it doesn’t recognize them:
        textRecognitionRequest.customWords = ["Pikachu", "Snorlax", "Charizard"]
     }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        textView.text = ""
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
//                put that request into an array,
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
        
//        let requests = [request]
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            guard let img = UIImage(named: "testImage")?.cgImage else {
//                fatalError("Missing image to scan")
//            }
//
//            let handler = VNImageRequestHandler(cgImage: img, options: [:])
//            try? handler.perform(requests)
//        }
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
