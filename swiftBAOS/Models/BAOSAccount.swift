//
//  baosAccount.swift
//  smome
//
//  Created by Henrik Engelbrink on 19.11.15.
//  Copyright © 2015 Henrik Engelbrink. All rights reserved.
//

import UIKit

let keyUsername = "keyUsername"
let keyPassword = "keyPassword"
let keyHost = "keyHost"
let keyCurrentAccount = "keyCurrentAccount"

class BAOSAccount: NSObject,NSCoding {

    var username:String!
    var password:String!
    var host:String!
    
    override init()
    {
        self.username = ""
        self.password = ""
        self.host = ""
    }
    
    init(username:String, password:String, host:String)
    {
        self.username = username
        self.password = password
        self.host = host
    }
    
    //MARK: - NSCoding Methoden
    required init(coder aDecoder: NSCoder) {
        super.init()
        self.username = aDecoder.decodeObjectForKey(keyUsername) as! String
        self.password = aDecoder.decodeObjectForKey(keyPassword) as! String
        self.host = aDecoder.decodeObjectForKey(keyHost) as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.username, forKey: keyUsername)
        aCoder.encodeObject(self.password, forKey: keyPassword)
        aCoder.encodeObject(self.host, forKey: keyHost)
    }
    
    //MARK: - Public Methoden
    func save()
    {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: keyCurrentAccount)
    }
    
    func logout()
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(keyCurrentAccount)
    }
    
    static func currentAccount() -> BAOSAccount? {
        var account:BAOSAccount? = nil
        let data:NSData? = NSUserDefaults.standardUserDefaults().objectForKey(keyCurrentAccount) as? NSData
        if data != nil {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? BAOSAccount
            return account
        }
        return account
    }
    
}
