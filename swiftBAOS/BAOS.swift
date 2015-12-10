//
//  BAOS.swift
//  HomeTest
//
//  Created by Henrik Engelbrink on 29.10.15.
//  Copyright © 2015 Henrik Engelbrink. All rights reserved.
//

import UIKit
import SwiftHTTP
import Starscream

let BAOSConnectionChangedNotification = "BAOSConnectionChangedNotification"

public class BAOS: NSObject,NSURLSessionDelegate,NSURLSessionDataDelegate,NSURLSessionTaskDelegate,HTTPSerializeProtocol,WebSocketDelegate {

    var url:NSURL!
    var host:String!
    var userID:String!
    var socket:WebSocket!
    var secondSocketConnect = false
    var indicationController:IndicationController!
    var reachability:Reachability!
    var applicationInBackground:Bool!
    
    static var shared:BAOS!
    
    //MARK: - Init Methoden
    init(host:String)
    {
        super.init()
        self.host = host
        self.url = NSURL(string: "http://\(self.host)")
        self.userID = ""
        self.applicationInBackground = false
        self.indicationController = IndicationController()
        do
        {
            self.reachability = try Reachability(hostname: self.host)
        }
        catch
        {
            print("Can't init Reachbility")
        }
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "connectionChanged:", name: ReachabilityChangedNotification, object: nil)
        do
        {
            try self.reachability.startNotifier()
        }
        catch
        {
            print("Cant start notifier")
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "willEnterForeground", name: UIApplicationWillEnterForegroundNotification, object: nil)
    }
    
    public class func createSharedWithHost(host:String)
    {
        self.shared = BAOS(host: host)
    }
    
    func createSocket()
    {
        self.socket = WebSocket(url: NSURL(string: "ws://\(self.host)/websocket")!)
        socket.delegate = self
        socket.headers["Cookie"] = "user=\(self.userID)"
        socket.connect()
    }
    
    //MARK: - Private Methoden
    func connectionChanged(notification:NSNotification)
    {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName(BAOSConnectionChangedNotification, object: self)
        }
        if self.reachability.currentReachabilityStatus == .NotReachable && !self.socket.isConnected
        {
            self.secondSocketConnect = false
            self.socket.connect()
        }
    }
    
    func didEnterBackground()
    {
        self.applicationInBackground = true
        self.socket.disconnect()
    }
    
    func willEnterForeground()
    {
        self.applicationInBackground = false
        self.socket.connect()
    }
    
    func sendRequest(urlPath:String, method:String, bodyData:NSData?, useAuth:Bool, completionClosure:(NSData -> Void)?, errorClosure:(NSError -> Void)?)
    {
        let request = NSMutableURLRequest(URL: NSURL(string: "\(self.url)\(urlPath)")!,
            cachePolicy: .UseProtocolCachePolicy,
            timeoutInterval: 20.0)
        request.HTTPMethod = method
        if bodyData != nil
        {
            request.HTTPBody = bodyData
        }
        if useAuth
        {
            let headers = [
                "cookie": "user=\(self.userID)"
            ]
            request.allHTTPHeaderFields = headers
        }
        
        let session = NSURLSession.sharedSession()
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            if (error != nil)
            {
                print("SendRequest Error \(urlPath) \(error)")
                if errorClosure != nil
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        errorClosure!(error!)
                    })
                }
            }
            else
            {
//                print(response)
                let httpResponse = response as? NSHTTPURLResponse
//                print(httpResponse?.statusCode)
                if httpResponse?.statusCode == 200
                {
                    if data != nil
                    {
                        if completionClosure != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                completionClosure!(data!)
                            })
                        }
                        
                    }
                    else
                    {
                        if errorClosure != nil
                        {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                let responseError = NSError(domain: "NoDataError", code: 123, userInfo: nil)
                                errorClosure!(responseError)
                            })
                        }
                    }
                }
                else if httpResponse?.statusCode == 204
                {
                    print("SET")
                }
                else
                {
                    if errorClosure != nil
                    {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let responseError = NSError(domain: "StatusCodeError", code: (httpResponse?.statusCode)!, userInfo: nil)
                            errorClosure!(responseError)
                        })
                    }
                }
            }
        })
        dataTask.resume()
    }
    
    func convertStringToDictionary(text: String) -> NSDictionary?
    {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding)
        do
        {
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
            return json
        }
        catch
        {
            print("Error Converting")
            return nil
        }
    }
    
    func sendIndicationPush(datapointType:String, datapointID:String, value:AnyObject)
    {
        switch(datapointType)
        {
        case "DPT1":
            let numValue = value as! NSNumber
            self.indicationController.dpt1Indication(datapointID, value: numValue)
            break
        case "DPT5":
            let numValue = value as! NSNumber
            self.indicationController.dpt5Indication(datapointID, value: numValue)
            break
        case "DPT11":
            let numValue = value as! NSNumber
            self.indicationController.dpt9Indication(datapointID, value: numValue)
        default:
//            print("Other Datapoint \(datapointType) - \(datapointID) - \(value)")
            break
        }
    }
    
    //MARK: - Login Methoden
    func login(username:String, password:String, loginSuccess:(Void -> Void)?, wrongCredentialsError:(Void -> Void)?, loginError:(NSError -> Void)?)
    {
        let dataString:String!
        if username.characters.count > 0 && password.characters.count > 0
        {
            dataString = "{\"username\": \"\(username)\", \"password\": \"\(password)\"}"
        }
        else
        {
            dataString = "{}"
        }

        let postData = NSData(data: dataString.dataUsingEncoding(NSUTF8StringEncoding)!)
        self.sendRequest("/rest/login", method: "POST", bodyData: postData, useAuth: false, completionClosure: { (data:NSData) -> Void in
                self.userID = String(data: data, encoding: NSUTF8StringEncoding)!
                if self.userID != nil && self.userID.characters.count > 0
                {
                    self.createSocket()
                    if loginSuccess != nil
                    {
                        loginSuccess!()
                    }
                }
                else
                {
                    if wrongCredentialsError != nil
                    {
                        wrongCredentialsError!()
                    }
                }
            
            }) { (error:NSError) -> Void in
                if loginError != nil
                {
                    loginError!(error)
                }
                print("BAOS-Login \(error)")
        }
    }
    
    //MARK: - Get Strucuture
    func getDataPoints(completion:([String:AnyObject] -> Void))
    {
        self.sendRequest("/rest/datapoints/descriptions?start=1&end=300", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
            do
            {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                completion(json!)
            }
            catch
            {
                print("Catch getDataPoints")
            }
            
            }) { (error:NSError) -> Void in
                print("getDataPoints-Error \(error)")
        }
    }
    
    func getRooms(completion:([String:AnyObject] -> Void))
    {
        self.sendRequest("/rest/structured/views/rooms", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
                do
                {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                    completion(json!)
                }
                catch
                {
                    print("Catch getRooms")
                }
            }) { (error:NSError) -> Void in
                print("getRooms-Error \(error)")
        }
    }
    
    func getFunctionsFromRoom(roomID:String, completion:([String:AnyObject] -> Void))
    {
        self.sendRequest("/rest/structured/views/rooms/\(roomID)", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
                do
                {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                    completion(json!)
                }
                catch
                {
                    print("Catch getRoomFunctions")
                }
            }) { (error:NSError) -> Void in
                print("getRoomFunctions-Error \(error)")
        }
    }
    
    //MARK: - Get Room Value Methoden
    func getValuesForRoom(roomID:String, completion:(NSArray -> Void)?)
    {
        self.sendRequest("/rest/structured/views/rooms/\(roomID)/values", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
                do
                {
                    let tmpArray = NSMutableArray()
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                    let arrFunctionValues = json!["function_values"] as! NSArray
                    for jsonFunctionValue in arrFunctionValues
                    {
                        let value = RoomFunctionValue(dict: jsonFunctionValue as! NSDictionary)
                        tmpArray.addObject(value)
                    }
                    completion!(tmpArray)
                }
                catch
                {
                    print("Catch getRoomValues")
                }
            }) { (error:NSError) -> Void in
                print("getValuesForRoom-Error \(error)")
        }
    }
    
    //MARK: - Get Datapoint Methoden
    func getDPT1Value(datapointID:String, completion:(NSNumber -> Void))
    {
        self.sendRequest("/rest/datapoints/values?start=\(datapointID)&count=1", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
            do
            {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                let arrValues = json!["datapoints_values"] as! NSArray
                let valDict = arrValues.firstObject as! NSDictionary
                let value = valDict["value"] as! NSNumber
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(value)
                })
            }
            catch
            {
                print("Catch getDPT1Value")
            }
            }) { (error:NSError) -> Void in
                
        }
    }
    
    func getDPT5Value(datapointID:String, completion:(NSNumber -> Void))
    {
        self.sendRequest("/rest/datapoints/values?start=\(datapointID)&count=1", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
                do
                {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                    let arrValues = json!["datapoints_values"] as! NSArray
                    let valDict = arrValues.firstObject as! NSDictionary
                    let value = valDict["value"] as! NSNumber
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion(value)
                    })
                }
                catch
                {
                    print("Catch getDPT5Value")
                }
            }) { (error:NSError) -> Void in
                
        }
    }
    
    func getDPT9Value(datapointID:String, completion:(NSNumber -> Void))
    {
        self.sendRequest("/rest/datapoints/values?start=\(datapointID)&count=1", method: "GET", bodyData: nil, useAuth: true, completionClosure: { (data:NSData) -> Void in
            do
            {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers) as? [String:AnyObject]
                let arrValues = json!["datapoints_values"] as! NSArray
                let valDict = arrValues.firstObject as! NSDictionary
                let value = valDict["value"] as! NSNumber
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completion(value)
                })
            }
            catch
            {
                print("Catch getDPT9Value")
            }
            }) { (error:NSError) -> Void in
                
        }
    }
    
    //MARK: - Set Datapoint Methoden
    func setDPT1Value(datapointID:String, value:Bool)
    {
        let fullURL = "\(self.url)/rest/datapoints/values"
        let headers = [
            "Cookie": "user=\(self.userID)"
        ]
        
        let vals = ["id": datapointID, "value": value]
        let params = ["datapoints_values": [vals], "command": 3]
        do {
            let opt = try HTTP.New(fullURL, method: .PUT, parameters: params, headers: headers, requestSerializer: self)
            opt.start()
            opt.onFinish = { response in
                print("StatusCode \(response.statusCode)")
                print("Text \(response.text)")
                print("Error \(response.error)")
            }
        } catch let error
        {
            print("setDPT1Value: \(error)")
        }
    }
    
    func setDPT3Value(datapointID:String, control:Bool, stepcode:Int)
    {
        let url = "\(self.url)/rest/datapoints/values"
        let headers = [
            "Cookie": "user=\(self.userID)"
        ]
        
        let value: [String: AnyObject] = ["Control": control, "StepCode": stepcode]
        let vals = ["id": datapointID, "value": value]
        let params = ["datapoints_values": [vals], "command": 3]
        do {
            let opt = try HTTP.New(url, method: .PUT, parameters: params, headers: headers, requestSerializer: self)
            opt.start()
        } catch let error
        {
            print("setDPT1Value: \(error)")
        }
    }
    
    //MARK: - HTTPSerializeProtocol
    public func serialize(request: NSMutableURLRequest, parameters: HTTPParameterProtocol) throws {
        if parameters.paramType() == .Dictionary
        {
            let dict = parameters as! NSDictionary
            
            do
            {
                let jsonData = try NSJSONSerialization.dataWithJSONObject(dict, options: .PrettyPrinted)
                request.HTTPBody = jsonData
//                let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
//                print("STRING:\(jsonString)")
            }
            catch
            {
                print("Serialize PUT Error")
            }
        }
    }
    
    //MARK: - WebSocket-Delegate
    public func websocketDidConnect(socket: WebSocket)
    {
        print("websocket is connected")
        self.secondSocketConnect = false
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?)
    {
        print("websocket is disconnected")
        if !self.applicationInBackground
        {
            if self.secondSocketConnect == false
            {
                self.secondSocketConnect = true
                self.socket.connect()
            }
            else
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(10) * Int64(NSEC_PER_SEC)), dispatch_get_main_queue(), { () -> Void in
                    print("n-Reconnect")
                    self.createSocket()
                })
            }
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String)
    {
        print("websocketDidReceiveMessage")
        let dict = self.convertStringToDictionary(text)
        let indications = dict!["indications"] as! NSDictionary
        let type = indications["type"] as! String
        if type  == "datapoint_ind"
        {
            let values = indications["values"] as! NSArray
            for obj in values
            {
                let valDict = obj as! NSDictionary
                //            print(valDict)
                let format = valDict["Format"] as! String
                let id = "\(valDict["id"] as! NSNumber)"
                let value = valDict["value"]
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.sendIndicationPush(format, datapointID: id, value: value!)
                })
            }
        }

    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: NSData)
    {
        print("got some data: \(data.length)")
    }
    
}
