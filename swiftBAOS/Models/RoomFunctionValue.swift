//
//  DatapointValue.swift
//  smome
//
//  Created by Henrik Engelbrink on 30.11.15.
//  Copyright © 2015 Henrik Engelbrink. All rights reserved.
//

import UIKit

class RoomFunctionValue: NSObject {

    var id:String!
    var value:NSNumber!
    var type:NSNumber!
    
    init(dict:NSDictionary)
    {
        let numID = dict["id"] as! NSNumber
        self.id = numID.stringValue
        let arrDPValues = dict["datapoints_values"] as! NSArray
        self.type = RoomFunctionValue.typeForArray(arrDPValues)
        //        self.type = CoreDataController.shared.typeForRoomFunctionWithID(id)
        switch(self.type)
        {
        case 2:
            let dpValueDict = arrDPValues.objectAtIndex(1)
            self.value = dpValueDict["value"] as! NSNumber
            break
        case 5:
            let dpValueDict = arrDPValues.objectAtIndex(2)
            self.value = dpValueDict["value"] as! NSNumber
            break
        case 7:
            let dpValueDict = arrDPValues.objectAtIndex(2)
            self.value = dpValueDict["value"] as! NSNumber
            break
        case 11:
            let dpValueDict = arrDPValues.objectAtIndex(0)
            self.value = dpValueDict["value"] as! NSNumber
            break
        default:
            break
        }
    }
    
    class func typeForArray(array:NSArray) -> Int
    {
        var type = 0
        if array.count == 2
        {
            let datapoint1Type = array[0]["Format"] as! String
            let datapoint2Type = array[1]["Format"] as! String
            
            if datapoint1Type == "DPT1" && datapoint2Type == "DPT1"
            {
                type = 2
            }
            else if datapoint1Type == "DPT9" && datapoint2Type == "DPT9"
            {
                type = 11
            }
        }
        else if array.count == 3
        {
            let datapoint1Type = array[0]["Format"] as! String
            let datapoint2Type = array[1]["Format"] as! String
            let datapoint3Type = array[2]["Format"] as! String
            
            if datapoint1Type == "DPT1" && datapoint2Type == "DPT3" && datapoint3Type == "DPT5"
            {
                type = 5
            }
            else if datapoint1Type == "DPT1" && datapoint2Type == "DPT1" && datapoint3Type == "DPT5"
            {
                type = 7
            }
        }
        return type
    }
}
