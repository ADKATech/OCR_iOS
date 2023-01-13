//
//  ViewController.swift
//  OCR_iOS
//
//  Created by iSeddiqi Apple on 13/01/2023.
//

import UIKit
import VisionKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    @IBAction func scanButtonPressed(_ sender: Any) {
        let vc = VNDocumentCameraViewController()
        vc.delegate = self
        present(vc, animated: true)
    }
    
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        print("Found \(scan.pageCount)")
        
        for i in 0 ..< scan.pageCount {
            let img = scan.imageOfPage(at: i)
            // ... your code here
            print("herelo")
        }
    }
}
