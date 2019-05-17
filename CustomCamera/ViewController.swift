

import UIKit
import AVFoundation
import Firebase
import FirebaseUI

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var myimageView: UIImageView!
    @IBOutlet var txtText: UITextField!
    
   
    @IBOutlet weak var cameraButton: UIButton!
    
    var captureSession = AVCaptureSession()
    
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    
    var cameraPreviewLayer:AVCaptureVideoPreviewLayer?
    
    var image: UIImage?
    
    var toggleCameraGestureRecognizer = UISwipeGestureRecognizer()
    
    var zoomInGestureRecognizer = UISwipeGestureRecognizer()
    var zoomOutGestureRecognizer = UISwipeGestureRecognizer()
    
     var ref = DatabaseReference.init()
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.txtText.delegate = self
        
        self.ref = Database.database().reference()
        //self.saveFIRData()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(ViewController.openGallery(tapGesture:)))
        myimageView.isUserInteractionEnabled = true
        myimageView.addGestureRecognizer(tapGesture)
        setupCaptureSession()
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
        toggleCameraGestureRecognizer.direction = .up
        toggleCameraGestureRecognizer.addTarget(self, action: #selector(self.switchCamera))
        view.addGestureRecognizer(toggleCameraGestureRecognizer)
        
        // Zoom In recognizer
        zoomInGestureRecognizer.direction = .right
        zoomInGestureRecognizer.addTarget(self, action: #selector(zoomIn))
        view.addGestureRecognizer(zoomInGestureRecognizer)
        
        // Zoom Out recognizer
        zoomOutGestureRecognizer.direction = .left
        zoomOutGestureRecognizer.addTarget(self, action: #selector(zoomOut))
        view.addGestureRecognizer(zoomOutGestureRecognizer)
        styleCaptureButton()
    }
    
    
    
    
    
    @objc func openGallery(tapGesture:  UITapGestureRecognizer){
        self.setypeImagePicker()    }
    
    @IBAction func btnSaveClick(_ sender: UIButton) {
        self.saveFIRData()
    }
    
    //this will hide the keyboard if the user touches outside the keyboard
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //this presses the return key
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return (true)
    }
    
    
    func saveFIRData(){
        guard let image = self.myimageView.image else { return }
        
        self.uploadImage(image) { url in
            guard let textField = self.txtText, let url = url else { return }
            
            self.saveImage(name: textField.text!, profileURL: url) { success in
                guard let success = success else {
                    print("Something went wrong!")
                    return
                }
                
                print("Save image succeeded!")
                
            }
        }
    }

    func styleCaptureButton() {
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraButton.layer.borderWidth = 5
        cameraButton.clipsToBounds = true
        cameraButton.layer.cornerRadius = min(cameraButton.frame.width, cameraButton.frame.height) / 2
    }
    
    func setupCaptureSession() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            } else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        currentDevice = backCamera
    }
    
    func setupInputOutput() {
        do {
            
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice!)
            captureSession.addInput(captureDeviceInput)
            photoOutput = AVCapturePhotoOutput()
            photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
            captureSession.addOutput(photoOutput!)
            
            
        } catch {
            print(error)
        }
    }
    
    func setupPreviewLayer() {
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.cameraPreviewLayer?.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        self.cameraPreviewLayer?.frame = view.frame
        
        self.view.layer.insertSublayer(self.cameraPreviewLayer!, at: 0)
    }
    
    
    @objc func switchCamera() {
        captureSession.beginConfiguration()
        
        // Change the device based on the current camera
        let newDevice = (currentDevice?.position == AVCaptureDevice.Position.back) ? frontCamera : backCamera
        
        // Remove all inputs from the session
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        // Change to the new input
        let cameraInput:AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        currentDevice = newDevice
        captureSession.commitConfiguration()
    }
    
    @objc func zoomIn() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor < 5.0 {
                let newZoomFactor = min(zoomFactor + 1.0, 5.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @objc func zoomOut() {
        if let zoomFactor = currentDevice?.videoZoomFactor {
            if zoomFactor > 1.0 {
                let newZoomFactor = max(zoomFactor - 1.0, 1.0)
                do {
                    try currentDevice?.lockForConfiguration()
                    currentDevice?.ramp(toVideoZoomFactor: newZoomFactor, withRate: 1.0)
                    currentDevice?.unlockForConfiguration()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    @IBAction func cameraButton_TouchUpInside(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("the segue identifier is \(String(describing: segue.identifier))")
        if segue.identifier == "Preview_Segue" {
            let previewViewController = segue.destination as! PreviewViewController
            previewViewController.image = self.image
        }
    }
  
    
}


    
   


extension ViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            self.image = UIImage(data: imageData)
            performSegue(withIdentifier: "Preview_Segue", sender: nil)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func setypeImagePicker() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.delegate = self
            imagePicker.isEditing = true
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
        myimageView.image = image
        self.dismiss(animated: true, completion: nil)
        
    }
    
    
}


extension ViewController {
    
    func uploadImage(_ image:UIImage, completion: @escaping ((_ url: URL?) -> ())){
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child(imageName + ".png")
        let imgData = image.pngData()
        let metaData = StorageMetadata()
        metaData.contentType = "image/png"
        storageRef.putData(imgData!, metadata: metaData) { (metaData, error) in
            if error == nil{
                print("success")
                storageRef.downloadURL(completion: { (url, error) in
                    completion(url)
                })
            } else{
                print("error in save image")
                completion(nil)
            }
        }
    }
    
    /*
     let dict = ["name" : "fai", "text" : txtText.text!]
     self.ref.child("chat").childByAutoId().setValue(dict)
    */
    
    func saveImage(name: String, profileURL:URL, completion: @escaping ((_ url: URL?) -> ())){
    
        let dict = ["name" : "Fai", "text" : txtText.text!, "profileUrl":profileURL.absoluteString] as [String: Any]
        self.ref.child("chat").childByAutoId().setValue(dict)
    
    
    }

    
    
    }


