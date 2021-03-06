//
//  Profile.swift
//  sample-videochat-webrtc-swift
//
//  Created by Vladimir Nybozhinsky on 12/7/18.
//  Copyright © 2018 QuickBlox. All rights reserved.
//

import Foundation
import Quickblox
import Security

struct ProfileConstants {
    static let profile = "curentProfile"
    static let user = "qbuser"
}

struct ProfileSecConstant {
    static let classValue = NSString(format: kSecClass)
    static let attrAccountValue = NSString(format: kSecAttrAccount)
    static let valueDataValue = NSString(format: kSecValueData)
    static let classGenericPasswordValue = NSString(format: kSecClassGenericPassword)
    static let attrServiceValue = NSString(format: kSecAttrService)
    static let attrAccessibleValue = NSString(format: kSecAttrAccessible)
    static let matchLimitValue = NSString(format: kSecMatchLimit)
    static let returnDataValue = NSString(format: kSecReturnData)
    static let matchLimitOneValue = NSString(format: kSecMatchLimitOne)
    static let attrAccessibleAfterFirstUnlockValue = NSString(format: kSecAttrAccessibleAfterFirstUnlock)
}

class Profile: NSObject, NSCoding, NSSecureCoding  {
    
    //MARK - Properties
    static var supportsSecureCoding: Bool {
        return true
    }
    
    var userData: QBUUser?
    
    //MARK: - Life Cycle
    init(userData: QBUUser?) {
        super.init()
        self.userData = userData
    }
    
    override init() {
        super.init()
        loadProfile()
    }
    
    /**
     *  Synchronize current profile in keychain.
     *
     *  @return whether synchronize was successful
     */
    func synchronize() -> OSStatus {
        assert(self.userData != nil, "Invalid parameter not satisfying: userData != nil")
        return self.saveData(self.userData as Any, forKey: ProfileConstants.profile)
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let userData = aDecoder.decodeObject(forKey: ProfileConstants.profile) as? QBUUser
        self.init(userData: userData)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(userData, forKey: ProfileConstants.profile)
    }
    
    /**
     *  Synchronize user data in keychain.
     *
     *  @param userData user data to synchronize
     *
     *  @return whether synchronize was successful
     */
    public func synchronizeWithUserData(userData: QBUUser) -> OSStatus {
        self.userData = userData;
        let status: OSStatus = synchronize()
        return status;
    }
    
    private func loadProfile() {
        guard let profile = self.loadObject(forKey: ProfileConstants.profile) else {
            return
        }
        self.userData = profile;
    }
    
    /**
     *  Remove all user data.
     *
     *  @return Whether clear was successful
     */
    public func clearProfile() -> OSStatus {
        let success: OSStatus = self.deleteObjectForKey(key: ProfileConstants.profile)
        self.userData = nil;
        return success;
    }
    
    //MARK: - Keychain
    func saveData(_ data: Any?, forKey key: String) -> OSStatus {
        var keychainQuery = getKeychainQueryFor(key: key)
        SecItemDelete(keychainQuery as CFDictionary)
        if let dataUser = data {
            keychainQuery[ProfileSecConstant.valueDataValue] = NSKeyedArchiver.archivedData(withRootObject: dataUser)
        }
        return SecItemAdd(keychainQuery as CFDictionary, nil)
    }
    
    func loadObject(forKey key: String) -> QBUUser? {
        var user: QBUUser? = nil
        var keychainQuery = getKeychainQueryFor(key: key)
        if let booleanTrue = kCFBooleanTrue {
            keychainQuery[ProfileSecConstant.returnDataValue] = booleanTrue
        }
        keychainQuery[ProfileSecConstant.matchLimitValue] = ProfileSecConstant.matchLimitOneValue
        var keyData: AnyObject?
        let status = SecItemCopyMatching(keychainQuery as CFDictionary, &keyData)
        if status == noErr, let keyData = keyData as? Data {
            user = NSKeyedUnarchiver.unarchiveObject(with: keyData) as? QBUUser
            return user
        }
        return user
    }
    
    private func deleteObjectForKey(key: String) -> OSStatus {
        let keychainQuery = self.getKeychainQueryFor(key: key)
        return SecItemDelete(keychainQuery as CFDictionary)
    }
    
    private func getKeychainQueryFor(key: String) -> [AnyHashable : Any] {
        return  [ProfileSecConstant.classValue: ProfileSecConstant.classGenericPasswordValue,
                 ProfileSecConstant.attrServiceValue: key,
                 ProfileSecConstant.attrAccountValue: key,
                 ProfileSecConstant.attrAccessibleValue: ProfileSecConstant.attrAccessibleAfterFirstUnlockValue]
    }
}


