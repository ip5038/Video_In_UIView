import UIKit
import PhotosUI

enum mediaType {
    case VIDEO
    case IMAGE
}

class ViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var uploadButton: UIButton!
    
    var type: mediaType? = nil
    var vidURL: URL? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Stylize button
        uploadButton.layer.cornerRadius = 3
        contentView.layer.borderWidth = 1
    }

    @IBAction func uploadButtonPressed(_ sender: UIButton) {
        var pickerConfig = PHPickerConfiguration()
        pickerConfig.filter = .any(of: [.images, .videos])
        let imagePicker = PHPickerViewController(configuration: pickerConfig)
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func uploadToMyDatabase() {
        var dataToUpload: Data? = nil
        if(type == .IMAGE) {
            dataToUpload = imageView.image?.pngData()
        } else if(type == .VIDEO) {
            if let url = vidURL {
                do {
                    dataToUpload = try Data(contentsOf: url, options: .mappedIfSafe)
                } catch {
                    NSLog("Error converting video to Data")
                }
            }
        }
        
        // Upload your data here to whatever database you want. dataToUpload is what you should upload
        print("Upload data: \(type)")
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
           dismiss(animated: true)
           guard let itemProvider = results.first?.itemProvider else { return }
           if itemProvider.canLoadObject(ofClass: UIImage.self) {  // For images
               itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                   if let safeImage = image as? UIImage {
                       DispatchQueue.main.async {
                           self.imageView.isHidden = false
                           self.videoView.isHidden = true
                           self.imageView.image = safeImage
                           self.type = .IMAGE
                           self.uploadToMyDatabase()
                       }
                   }
               }
           } else if(itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)) { // For videos
               itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                   // We need to first save the url form tmp directory to directory we have control over. Then load the video using the url from
                   // the directory we control
                   if let safeURL = url {
                       print("safeURL: \(safeURL)")
                       let fileName = "fileToUpload.\(safeURL.pathExtension)"
                       let newURL = URL(fileURLWithPath: NSTemporaryDirectory() + fileName)
                       try? FileManager.default.copyItem(at: safeURL, to: newURL)
                       print("newURL: \(newURL)")
                      
                       DispatchQueue.main.async {
                           // Play video in videoView
                           let player = AVPlayer(url: newURL)
                           let playerLayer = AVPlayerLayer(player: player)
                           self.imageView.isHidden = true
                           self.videoView.isHidden = false
                           self.vidURL = newURL
                           playerLayer.videoGravity = .resizeAspect
                           playerLayer.frame = self.videoView.bounds
                           self.videoView.layer.addSublayer(playerLayer)
                           player.play()
                           self.type = .VIDEO
                           self.uploadToMyDatabase()
                       }
                      
                   }
               }
           }
       }
}
