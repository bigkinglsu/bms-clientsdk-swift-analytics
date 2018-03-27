/*
 *     Copyright 2016 IBM Corp.
 *     Licensed under the Apache License, Version 2.0 (the "License");
 *     you may not use this file except in compliance with the License.
 *     You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 */



// MARK: - Swift 3

#if swift(>=3.0)

import UIKit
#if UseCarthage
    import ZipArchive
#else
    import SSZipArchive
#endif
import BMSCore

public class Feedback{
    
    struct FeedbackJson{
        let id:String
        let comments:[String]
        let screenName:String
        let screenWidth:Int
        let screenHeight:Int
        let sessionID:String
        let username:String
        var timeSent:String
        
        init(json:[String:Any]){
            id = json["id"] as? String ?? ""
            comments = json["comments"] as? [String] ?? []
            screenName = json["screenName"] as? String ?? ""
            screenWidth = json["screenWidth"] as? Int ?? 0
            screenHeight = json["screenHeight"] as? Int ?? 0
            sessionID = json["sessionID"] as? String ?? ""
            username = json["username"] as? String ?? ""
            timeSent = json["timeSent"] as? String ?? ""
        }
        
        var dictionaryRepresentation: [String: Any] {
            return [
                "id" : id,
                "comments" : comments,
                "screenName" : screenName,
                "screenWidth" : screenWidth,
                "screenHeight" : screenHeight,
                "sessionID" : sessionID,
                "username" : username,
                "timeSent" : timeSent
            ]
        }
    }
    

    struct sendEntry {
        var timeSent: String
        var sendArray: [String]
        init(timeSent:String, sendArray:[String]){
            self.timeSent = timeSent
            self.sendArray = sendArray
        }
    }

    
    struct AppFeedBackSummary {
        var saved: [String]
        var send: [sendEntry]
        
        init(json: [String: Any]){
            self.saved = json["saved"] as? [String] ?? []
            self.send = []
            let sendArray:[String: [String]] = (json["send"] as? [String : [String]]) ?? [:]
            for key in sendArray.keys {
                send.append(sendEntry(timeSent: key, sendArray: sendArray[key]!))
            }
        }
        
        func jsonRepresentation() ->String {
            var savedString:String = "["
            for i in 0..<self.saved.count {
                savedString = savedString + "\""+self.saved[i]+"\""
                if i != self.saved.count-1 { savedString = savedString + ","}
            }
            savedString = savedString + "]"
            
            var sendArray:String = "{"
            for i in 0..<self.send.count {
                let ts:String = "\""+self.send[i].timeSent+"\""+":"
                var sa:String = "["
                for j in 0..<self.send[i].sendArray.count {
                    sa = sa + "\"" + self.send[i].sendArray[j] + "\""
                    if j != self.send[i].sendArray.count-1 { sa = sa + ","}
                }
                sa = sa + "]"
                if i != self.send.count-1 { sa = sa + "," }
                sendArray = sendArray + ts + sa
            }
            sendArray = sendArray + "}"
            
            let returnStr:String = "{\"saved\":"+savedString+", \"send\":"+sendArray+"}"
            return returnStr
        }
        
        var dictionaryRepresentation: [String: Any] {
            return [
                "saved" : self.saved,
                "send" : self.send
            ]
        }
    }
    
    internal static var currentlySendingFeedbackdata = false
    static var screenshot:UIImage?
    static var messages:[String] = [String]()
    static var instanceName:String?
    static var creationDate:String?
    static var timeSent:String?

    public static func invokeFeedback() -> Void {
        let uiViewController = topController(nil);
        let instance:String = NSStringFromClass(uiViewController.classForCoder)
        Feedback.instanceName = instance.replacingOccurrences(of: "_", with: "")
        Feedback.creationDate = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
        Feedback.screenshot = takeScreenshot(uiViewController.view)
        
        let feedbackBundle = Bundle(for: UIImageControllerViewController.self)
        let feedbackStoryboard: UIStoryboard!
        feedbackStoryboard = UIStoryboard(name: "Feedback", bundle: feedbackBundle)
        let feedbackViewController : UIViewController = feedbackStoryboard.instantiateViewController(withIdentifier: "feedbackImageView") as! UIViewController
        uiViewController.present(feedbackViewController, animated: true, completion: nil)
    }
    
    public static func takeScreenshot(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    public static func send(fromSentButton:Bool) -> Void {
        /*Sudo code:
         If called from send action
            - Save Image
            - Save other image related info into json file
            - Update summary json (AppFeedBackSummary.json)
         fi
         -Get the list of images need to send
         -iterate the list
             - Add timeSent to feedback.json
             - create zip and send
             - Send the file
             - if Sucess Update summary json (AppFeedBackSummary.json)
        */

        if fromSentButton == true {
            saveImage(Feedback.screenshot!)
            createFeedbackJsonFile()
            updateSummaryJsonFile(getInstanceName(), timesent: "", remove: false)
        }
        let filesToSend:[String] = getListOfFeedbackFilesToSend()
        for i in 0..<filesToSend.count{
            if BMSLogger.fileManager.fileExists(atPath: BMSLogger.feedbackDocumentPath+filesToSend[i]) {
                Feedback.timeSent = String(Int((Date().timeIntervalSince1970 * 1000.0).rounded()))
                Feedback.timeSent = addAndReturnTimeSent(instanceName: filesToSend[i], timeSent: Feedback.timeSent!)
                createZip(instanceName: filesToSend[i])
                sendFeedback(instanceName: filesToSend[i])
            }
        }
    }
    
    // MARK: - Internal methods
    
    internal static func topController(_ parent:UIViewController? = nil) -> UIViewController {
        if let vc = parent {
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return topController(selected)
            } else if let nav = vc as? UINavigationController, let top = nav.topViewController {
                return topController(top)
            } else if let presented = vc.presentedViewController {
                return topController(presented)
            } else {
                return vc
            }
        } else {
            return topController(UIApplication.shared.keyWindow!.rootViewController!)
        }
    }
    
    internal static func sendFeedback(instanceName: String){
        let zipFile:String = BMSLogger.feedbackDocumentPath + instanceName + ".zip"
        let instanceDocPath:String = BMSLogger.feedbackDocumentPath + instanceName
        
        func completionHandler() -> BMSCompletionHandler {
            return {
                (response: Response?, error: Error?) -> Void in

                let response = response
                if error == nil && response?.statusCode == 201 {
                    Analytics.logger.debug(message: "Feedback data successfully sent to the server.")
                    print("\nFeedback sent successfully: " + String(describing: response?.isSuccessful))
                    print("Status code: " + String(describing: response?.statusCode))
                    if let responseText = response?.responseText {
                        print("Response text: " + responseText)
                    }
                    print("\n")
                    
                    do {
                        try BMSLogger.fileManager.removeItem(atPath: zipFile)
                        try BMSLogger.fileManager.removeItem(atPath: instanceDocPath)
                    }catch let error{ print(error.localizedDescription)}
                    updateSummaryJsonFile(instanceName, timesent: Feedback.timeSent!, remove: true)
                }
            }
        }
        
        send(completionHandler: completionHandler(), uploadFileName: zipFile)
    }
    
    // Same as the other send() method but for analytics
    internal static func send(completionHandler userCallback: BMSCompletionHandler? = nil, uploadFileName:String) {
        
        //Wait for sending next file
        while currentlySendingFeedbackdata {
            sleep(1)
        }

        guard !currentlySendingFeedbackdata else {
            
            Analytics.logger.info(message: "Ignoring Analytics.sendFeedback() until the previous send request finishes.")
            
            return
        }
        
        currentlySendingFeedbackdata = true
        
        // Internal completion handler - wraps around the user supplied completion handler (if supplied)
        let feedbackSendCallback: BMSCompletionHandler = { (response: Response?, error: Error?) in
            
            currentlySendingFeedbackdata = false
            
            if error == nil && response?.statusCode == 201 {
                Analytics.logger.debug(message: "Feedback data successfully sent to the server.")
            }
            else {
                
                var debugMessage = ""
                if let response = response {
                    if let statusCode = response.statusCode {
                        debugMessage += "Status code: \(statusCode). "
                    }
                    if let responseText = response.responseText {
                        debugMessage += "Response: \(responseText). "
                    }
                }
                if let error = error {
                    debugMessage += " Error: \(error)."
                }
                
                BMSLogger.internalLogger.error(message: "Request to send Feedback data has failed. To see more details, set Logger.sdkDebugLoggingEnabled to true, or send Feedback with a completion handler to retrieve the response and error. Reason: \(debugMessage)")
                BMSLogger.internalLogger.debug(message: debugMessage)
            }
            
            userCallback?(response, error)
        }
        
        
        // Use a serial queue to ensure that the same logs do not get sent more than once
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: {
            do {
                //let uploadFile = BMSLogger.feedbackDocumentPath + uploadFileName
                let uploadFile = uploadFileName
                
                if BMSLogger.fileManager.fileExists(atPath: uploadFileName){
                    
                    let fileurl = URL(fileURLWithPath: uploadFile)
                    let fileData = try Data(contentsOf: fileurl)
                    
                    // Set data
                    let body = NSMutableData()
                    body.append(fileData)
                    
                    if let request: BaseRequest = try BMSLogger.buildLogSendRequestForFeedback(completionHandler:feedbackSendCallback) {
                        request.send(requestBody: body as Data, completionHandler: feedbackSendCallback)
                    }
                }
                else {
                    feedbackSendCallback(nil, BMSAnalyticsError.noLogsToSend)
                }
            }
            catch let error as NSError {
                feedbackSendCallback(nil, error)
            }
        })
    }
    
    public static func saveImage(_ image: UIImage) -> Void{
        if let data = UIImagePNGRepresentation(image) {
            var objcBool:ObjCBool = true
            let isExist = FileManager.default.fileExists(atPath: BMSLogger.feedbackDocumentPath+getInstanceName()+"/", isDirectory: &objcBool)
            
            // If the folder with the given path doesn't exist already, create it
            if isExist == false{
                do{
                    try FileManager.default.createDirectory(atPath: BMSLogger.feedbackDocumentPath+getInstanceName()+"/", withIntermediateDirectories: true, attributes: nil)
                }catch{
                    print("Something went wrong while creating a new folder")
                }
            }
            
            let filename = BMSLogger.feedbackDocumentPath+getInstanceName()+"/image.png";
            print("Creating image at" + filename)
            let result = FileManager.default.createFile(atPath: filename, contents: data, attributes: nil)
            if result != true {
                print("Failed to create image file")
            }
        }
    }
    
    internal static func getInstanceName() -> String {
        return Feedback.instanceName!+"_"+Feedback.creationDate!;
    }

    
    /* Function adds timeSent to feedback.json if its not exists otherwise returns the timestamp*/
    internal static func addAndReturnTimeSent(instanceName : String, timeSent: String) -> String{
        let instanceJsonFile:String = BMSLogger.feedbackDocumentPath+instanceName+"/feedback.json"
        let feedbackData = convertFileToData(filepath: instanceJsonFile)
        do {
            let json = try JSONSerialization.jsonObject(with: feedbackData!, options: JSONSerialization.ReadingOptions.mutableContainers)
            var feedback = FeedbackJson(json: json as! [String : Any])
            if feedback.timeSent.isEmpty {
                feedback.timeSent=timeSent
                write(toFile: instanceJsonFile, feedbackdata: convertToJSON(feedback.dictionaryRepresentation)!, append: false)
                return timeSent
            }else {
               return feedback.timeSent
            }
        }catch let error{
            print("addTimeSent: Error: " + error.localizedDescription)
        }
        return ""
    }
    
    internal static func getListOfFeedbackFilesToSend() -> [String] {
        let afbsFile = BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)
        if afbs != nil {
            do {
                let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
                let summary = AppFeedBackSummary(json: json as! [String : Any])
                return summary.saved
            }catch let jsonErr {
                print("getListOfFeedbackFilesToSend: Error : " + jsonErr.localizedDescription)
            }
        }
        return [""]
    }
    
    internal static func updateSummaryJsonFile(_ entry: String, timesent:String, remove:Bool) -> Void {
        let afbsFile = BMSLogger.feedbackDocumentPath+"AppFeedBackSummary.json"
        let afbs = convertFileToData(filepath: afbsFile)
        var summary:AppFeedBackSummary
        do {
            if afbs == nil {
                summary = AppFeedBackSummary(json:[:])
            }else {
                let json = try JSONSerialization.jsonObject(with: afbs!, options: JSONSerialization.ReadingOptions.mutableContainers)
                summary = AppFeedBackSummary(json: json as! [String : Any])
            }
            
            if remove == false {
                summary.saved.append(entry)
            }else {
                if summary.saved.contains(entry) == true {
                    //Remove from saved
                    for i in 0..<summary.saved.count {
                        if summary.saved[i] == entry {
                            summary.saved.remove(at: i)
                            break
                        }
                    }
                    
                    var updated:Bool = false
                    //Add to send
                    for i in 0..<summary.send.count {
                        if summary.send[i].timeSent == timesent {
                            summary.send[i].sendArray.append(entry)
                            updated = true
                            break
                        }
                    }
                    
                    if updated == false {
                        summary.send.append(sendEntry(timeSent:timesent, sendArray:[entry]))
                        updated = true
                    }
                }else {
                    //No need to write anything
                    return
                }
            }
            //print("updateSummaryJsonFile: FeedbackSummary.json : " + convertToJSON(summary.dictionaryRepresentation)!)
            //write(toFile: afbsFile, feedbackdata: convertToJSON(summary.dictionaryRepresentation)!, append: false)
            print("updateSummaryJsonFile: FeedbackSummary.json : " + summary.jsonRepresentation())
            write(toFile: afbsFile, feedbackdata: summary.jsonRepresentation(), append: false)
        }catch let jsonErr {
            print("updateSummaryJsonFile: Exception:" + jsonErr.localizedDescription)
        }
    }
    
    internal static func createZip(instanceName:String) -> Void {
        let zipPath = BMSLogger.feedbackDocumentPath+instanceName+".zip";
        let sampleDataPath = BMSLogger.feedbackDocumentPath+instanceName;
        let password = ""
        
        let success = SSZipArchive.createZipFile(atPath: zipPath,
                                                 withContentsOfDirectory: sampleDataPath,
                                                 keepParentDirectory: false,
                                                 compressionLevel: -1,
                                                 password: password.isEmpty == false ? password : nil,
                                                 aes: true,
                                                 progressHandler: nil)
        if success {
            print("Success zip")
        } else {
            print("No success zip")
        }
    }
    
    internal static func convertFileToString(filepath : String) -> String? {
        let fileURL = URL(string: filepath)
        var fileContent:String? = ""
        do {
            fileContent = try String(contentsOf: fileURL!, encoding: .utf8)
        }catch{}
        return fileContent
    }

    internal static func convertFileToData(filepath : String) -> Data? {
        var fileContent:Data? = nil
        do {
            fileContent = try Data(contentsOf: URL(fileURLWithPath: filepath), options: .mappedIfSafe)
        } catch let error {
            print("convertFileToData : Error :" + error.localizedDescription)
            return nil
        }
        return fileContent
    }
    
    internal static func createFeedbackJsonFile() -> Void {
        let screenName = getInstanceName()
        let deviceID = BMSAnalytics.uniqueDeviceId
        let id = deviceID! + "_" + screenName

        let screenSize = UIScreen.main.bounds
        let screenWidth:Int = Int(screenSize.width)
        let screenHeight:Int = Int(screenSize.height)
        let sessionId:String = BMSAnalytics.lifecycleEvents[Constants.Metadata.Analytics.sessionId] as! String
        let userID:String
            
        if( Analytics.userIdentity == nil ){
            userID = "UNKNOWN"
        } else {
            userID = (Analytics.userIdentity)!
        }
        
        let jsonObject: [String: Any] = [
            "id": id,
            "comments": Feedback.messages,
            "screenName": screenName,
            "screenWidth": screenWidth,
            "screenHeight": screenHeight,
            "sessionID": sessionId,
            "username": userID
        ]
        
        let feedbackJsonString = convertToJSON(jsonObject)
        guard feedbackJsonString != nil else {
            let errorMessage = "Failed to write feedback json data to file. This is likely because the feedback data could not be parsed."
            print(errorMessage)
            return
        }
        let filename = BMSLogger.feedbackDocumentPath+getInstanceName()+"/feedback.json";
        write(toFile: filename, feedbackdata: feedbackJsonString!, append: false)
    }
    
    internal static func convertToJSON(_ feedbackData: [String: Any]?) -> String? {
        let logData: Data
        do {
            logData = try JSONSerialization.data(withJSONObject: feedbackData as Any, options: [])
        } catch let error {
            print ("convertToJSON: Error: " + error.localizedDescription)
            return nil
        }
        
        return String(data: logData, encoding: .utf8)
    }
    
    // Append log message to the end of the log file
    internal static func write(toFile file: String, feedbackdata : String, append:Bool) {

        do {
            //Remove the file if its already exists
            if append == false {
                if BMSLogger.fileManager.fileExists(atPath: file) {
                    try BMSLogger.fileManager.removeItem(atPath: file)
                }
            }
            
            if !BMSLogger.fileManager.fileExists(atPath: file) {
                BMSLogger.fileManager.createFile(atPath: file, contents: nil, attributes: nil)
            }
            
            let fileHandle = FileHandle(forWritingAtPath: file)
            let data = feedbackdata.data(using: .utf8)
            
            if fileHandle != nil && data != nil {
                fileHandle!.seekToEndOfFile()
                fileHandle!.write(data!)
                fileHandle!.closeFile()
            }
            else {
                let errorMessage = "Cannot write to file: \(file)."
                print(errorMessage)
            }
        }catch {}
    }
}

/**************************************************************************************************/
    // MARK: - Swift 2
#else
    
#endif


