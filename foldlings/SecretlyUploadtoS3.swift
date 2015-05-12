/*
* Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

import UIKit
import AssetsLibrary

class SecretlyUploadtoS3 {
    
    var uploadRequests = Array<AWSS3TransferManagerUploadRequest?>()
    var uploadFileURLs = Array<NSURL?>()
    
    init(){
        var error = NSErrorPointer()
        if !NSFileManager.defaultManager().createDirectoryAtPath(
            NSTemporaryDirectory().stringByAppendingPathComponent("upload"),
            withIntermediateDirectories: true,
            attributes: nil,
            error: error) {
                println("Creating 'upload' directory failed. Error: \(error)")
        }
    
    }
    
//    @IBAction func showAlertController(barButtonItem: UIBarButtonItem) {
//        let alertController = UIAlertController(
//            title: "Available Actions",
//            message: "Choose your action.",
//            preferredStyle: .ActionSheet)
//        
//        let selectPictureAction = UIAlertAction(
//            title: "Select Pictures",
//            style: .Default) { (action) -> Void in
//return
//        }
//        alertController.addAction(selectPictureAction)
//        
//        let cancelAllUploadsAction = UIAlertAction(
//            title: "Cancel All Uploads",
//            style: .Default) { (action) -> Void in
//                //self.cancelAllUploads()
//        }
//        alertController.addAction(cancelAllUploadsAction)
//        
//        let cancelAction = UIAlertAction(
//            title: "Cancel",
//            style: .Cancel) { (action) -> Void in }
//        alertController.addAction(cancelAction)
//        
//        self.presentViewController(
//            alertController,
//            animated: true) { () -> Void in }
//    }
    
    func upload(uploadRequest: AWSS3TransferManagerUploadRequest) {
        let transferManager = AWSS3TransferManager.defaultS3TransferManager()
        
        transferManager.upload(uploadRequest).continueWithBlock { (task) -> AnyObject! in
            if let error = task.error {
                if error.domain == AWSS3TransferManagerErrorDomain as String {
                    if let errorCode = AWSS3TransferManagerErrorType(rawValue: error.code) {
                        switch (errorCode) {
                        case .Cancelled, .Paused:
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            })
                            break;
                            
                        default:
                            println("upload() failed: [\(error)]")
                            break;
                        }
                    } else {
                        println("upload() failed: [\(error)]")
                    }
                } else {
                    println("upload() failed: [\(error)]")
                }
            }
            
            if let exception = task.exception {
                println("upload() failed: [\(exception)]")
            }
            
            if task.result != nil {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if let index = self.indexOfUploadRequest(self.uploadRequests, uploadRequest: uploadRequest) {
                        self.uploadRequests[index] = nil
                        self.uploadFileURLs[index] = uploadRequest.body
                        
                    }
                })
            }
            return nil
        }
    }
    
    func cancelAllDownloads() {
        for (index, uploadRequest) in enumerate(self.uploadRequests) {
            if let uploadRequest = uploadRequest {
                uploadRequest.cancel().continueWithBlock({ (task) -> AnyObject! in
                    if let error = task.error {
                        println("cancel() failed: [\(error)]")
                    }
                    if let exception = task.exception {
                        println("cancel() failed: [\(exception)]")
                    }
                    return nil
                })
            }
        }
    }

    func elcImagePickerController(picker: AnyObject!, didFinishPickingMediaWithInfo info: [AnyObject]!) {
//        
//        for (index, imageDictionary) in enumerate(info) {
//            if let imageDictionary = imageDictionary as? Dictionary<String, AnyObject> {
//                if let mediaType = imageDictionary[UIImagePickerControllerMediaType] as? String {
//                    if mediaType == ALAssetTypePhoto {
//                        if let image = imageDictionary[UIImagePickerControllerOriginalImage] as? UIImage {
                            let image = UIImage()
                            let fileName = NSProcessInfo.processInfo().globallyUniqueString.stringByAppendingString(".png")
                            let filePath = NSTemporaryDirectory().stringByAppendingPathComponent("upload").stringByAppendingPathComponent(fileName)
                            let imageData = UIImagePNGRepresentation(image)
                            imageData.writeToFile(filePath, atomically: true)
                            
                            let uploadRequest = AWSS3TransferManagerUploadRequest()
                            uploadRequest.body = NSURL(fileURLWithPath: filePath)
                            uploadRequest.key = fileName
                            uploadRequest.bucket = S3_BUCKET_NAME
                            
                            self.uploadRequests.append(uploadRequest)
                            self.uploadFileURLs.append(nil)
                            
                            self.upload(uploadRequest)

    }
    
    func indexOfUploadRequest(array: Array<AWSS3TransferManagerUploadRequest?>, uploadRequest: AWSS3TransferManagerUploadRequest?) -> Int? {
        for (index, object) in enumerate(array) {
            if object == uploadRequest {
                return index
            }
        }
        return nil
    }
}
