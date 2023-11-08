//
//  ViewController.swift
//  FacediDchecker
//
//  Created by avinash on 08/11/23.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    //MARK: - Variables

    private var drawing: [CAShapeLayer] = []
    
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let captureSession = AVCaptureSession()
    private lazy var previewlaye = AVCaptureVideoPreviewLayer(session: captureSession)
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addcameraInput()
        showCamerafeed()
        
        getCameraFrames()
        captureSession.startRunning()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        previewlaye.frame = view.frame
    }
    //MARK: - Helper Funcations
    private func addcameraInput(){
        guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera ,.builtInDualCamera , .builtInWideAngleCamera] , mediaType: .video, position: .front).devices.first else {
            fatalError(" No camera dedicated")
        }
        
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        captureSession.addInput(cameraInput)
    }
    private func showCamerafeed(){
        previewlaye.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewlaye)
        previewlaye.frame = view.frame
    }
    
    private func getCameraFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera frame processing queue"))
        
        captureSession.addOutput(videoDataOutput)
        
        guard let connection = videoDataOutput.connection(with: .video) , connection.isVideoOrientationSupported else {
            return
        }
        connection.videoOrientation = .portrait
        
    }
    
    private func detectFace(image : CVPixelBuffer){
        let faceDetectRequest = VNDetectFaceLandmarksRequest{VNRequest, error in
            
            DispatchQueue.main.async {
                if let results = VNRequest.results as? [VNFaceObservation], results.count > 0 {
                    print(results.count)
                } else {
                    print("No Face dedicated")
                }
            }
            
           
        }
        
        let imageRequestHandle = VNImageRequestHandler(cvPixelBuffer: image , orientation:  .leftMirrored , options: [:])
        try? imageRequestHandle.perform([faceDetectRequest])
    }
    
    private func handlefaceetectResults(observedFaces:[VNFaceObservation]) {
        clearDrawings()
        
        let faceBoundingBoxes : [CAShapeLayer] = observedFaces.map({
            (observedFace: VNFaceObservation) -> CAShapeLayer in
            
            let faceBoundingOnscreen = previewlaye.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            let faceBoundingBoxPath = CGPath(rect: faceBoundingOnscreen, transform: nil)
            let faceBoundingBoxShap = CAShapeLayer()
            
            faceBoundingBoxShap.path = faceBoundingBoxPath
            faceBoundingBoxShap.fillColor = UIColor.clear.cgColor
            faceBoundingBoxShap.strokeColor = UIColor.green.cgColor
            
            return faceBoundingBoxShap
        })
        faceBoundingBoxes.forEach {faceBoundingBox in view.layer.addSublayer(faceBoundingBox)
            drawing  = faceBoundingBoxes
        }
        
    }
    
    private func clearDrawings() {
        drawing.forEach({ drawing in drawing.removeFromSuperlayer()})
    }
}

extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
   
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Recevied")
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("unable to get image")
            return
        }
        detectFace(image: frame)
    }
}
