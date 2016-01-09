//
//  baosAccount.swift
//  smome
//
//  Created by Henrik Engelbrink on 19.11.15.
//  Copyright © 2015 Henrik Engelbrink. All rights reserved.
//

import UIKit

public let keyUsername = "keyUsername"
public let keyPassword = "keyPassword"
public let keyHost = "keyHost"
public let keyCurrentAccount = "keyCurrentAccount"

public  class BAOSAccount: NSObject,NSCoding {

    public var username:String!
    public var password:String!
    public var host:String!
    
    public override init()
    {
        self.username = ""
        self.password = ""
        self.host = ""
    }
    
    public init(username:String, password:String, host:String)
    {
        self.username = username
        self.password = password
        self.host = host
    }
    
    //MARK: - NSCoding Methoden
    required public init(coder aDecoder: NSCoder) {
        super.init()
        self.username = aDecoder.decodeObjectForKey(keyUsername) as! String
        self.password = aDecoder.decodeObjectForKey(keyPassword) as! String
        self.host = aDecoder.decodeObjectForKey(keyHost) as! String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.username, forKey: keyUsername)
        aCoder.encodeObject(self.password, forKey: keyPassword)
        aCoder.encodeObject(self.host, forKey: keyHost)
    }
    
    //MARK: - Public Methoden
    public func save()
    {
        let data = NSKeyedArchiver.archivedDataWithRootObject(self)
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: keyCurrentAccount)
    }
    
    public func logout()
    {
        NSUserDefaults.standardUserDefaults().removeObjectForKey(keyCurrentAccount)
    }
    
    public static func currentAccount() -> BAOSAccount? {
        var account:BAOSAccount? = nil
        let data:NSData? = NSUserDefaults.standardUserDefaults().objectForKey(keyCurrentAccount) as? NSData
        if data != nil {
            account = NSKeyedUnarchiver.unarchiveObjectWithData(data!) as? BAOSAccount
            return account
        }
        return account
    }
    
}
