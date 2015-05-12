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
    func uploadToS3(image:UIImage,named:String){
        
        // create a local image that we can use to upload to s3
        var path:String = NSTemporaryDirectory().stringByAppendingPathComponent("image.png")
        var imageData:NSData = UIImagePNGRepresentation(image)
        imageData.writeToFile(path, atomically: true)
        
        
        // once the image is saved we can use the path to create a local fileurl
        var url:NSURL = NSURL(fileURLWithPath: path)!
        
        // next we set up the S3 upload request manager
       let uploadRequest = AWSS3TransferManagerUploadRequest()
        // set the bucket
        uploadRequest?.bucket = S3_BUCKET_NAME
        // I want this image to be public to anyone to view it so I'm setting it to Public Read
        uploadRequest?.ACL = AWSS3ObjectCannedACL.PublicRead
        // set the image's name that will be used on the s3 server. I am also creating a folder to place the image in
        uploadRequest?.key = "\(UIDevice.currentDevice().identifierForVendor.UUIDString)/\(named)-\(NSDate.timeIntervalSinceReferenceDate()).png"
        // set the content type
        uploadRequest?.contentType = "image/png"
        // and finally set the body to the local file path
        uploadRequest?.body = url;
    
        
        // now the upload request is set up we can creat the transfermanger, the credentials are already set up in the app delegate
        var transferManager:AWSS3TransferManager = AWSS3TransferManager.defaultS3TransferManager()
        // start the upload
        transferManager.upload(uploadRequest).continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock:{ [unowned self]
            task -> AnyObject in
            
            // once the uploadmanager finishes check if there were any errors
            if(task.error != nil){
                NSLog("%@", task.error);
            }else{ // if there aren't any then the image is uploaded!
                // this is the url of the image we just uploaded
//                NSLog("https://s3.amazonaws.com/s3-demo-swift/foldername/image.png");
            }
            
//            self.removeLoadingView()
            return "all done";
            })
        
    }
    
}

