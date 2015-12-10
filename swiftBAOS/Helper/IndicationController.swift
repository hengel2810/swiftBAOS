//
//  IndicationController.swift
//  smome
//
//  Created by Henrik Engelbrink on 18.11.15.
//  Copyright © 2015 Henrik Engelbrink. All rights reserved.
//

import UIKit

let DPT1IndicationNotification = "DPT1IndicationNotification"
let DPT5IndicationNotification = "DPT5IndicationNotification"
let DPT9IndicationNotification = "DPT9IndicationNotification"

let keyDatapointID = "id"
let keyValue = "value"

public class IndicationController: NSObject
{
    public func dpt1Indication(id:String, value:NSNumber)
    {
        let dict:[String:AnyObject] = [keyDatapointID:id,keyValue:value]
        NSNotificationCenter.defaultCenter().postNotificationName(DPT1IndicationNotification, object: self, userInfo: dict)
    }
    
    public func dpt5Indication(id:String, value:NSNumber)
    {
        let dict:[String:AnyObject] = [keyDatapointID:id,keyValue:value]
        NSNotificationCenter.defaultCenter().postNotificationName(DPT5IndicationNotification, object: self, userInfo: dict)
    }
    
    public func dpt9Indication(id:String, value:NSNumber)
    {
        let dict:[String:AnyObject] = [keyDatapointID:id,keyValue:value]
        NSNotificationCenter.defaultCenter().postNotificationName(DPT9IndicationNotification, object: self, userInfo: dict)
    }
    
}
