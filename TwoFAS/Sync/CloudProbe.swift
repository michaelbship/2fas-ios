//
//  This file is part of the 2FAS iOS app (https://github.com/twofas/2fas-ios)
//  Copyright © 2025 Two Factor Authentication Service, Inc.
//  Contributed by Zbigniew Cisiński. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program. If not, see <https://www.gnu.org/licenses/>
//

import Foundation
import CloudKit
import Common

public protocol CloudProbing: AnyObject {
    func checkForVaults(completion: @escaping (Result<[CKRecordZone.ID: VaultVersion], Error>) -> Void)
}

public final class CloudProbe: CloudProbing {
    private let container: CKContainer
    private let database: CKDatabase
    
    private var completion: ((Result<[CKRecordZone.ID: VaultVersion], Error>) -> Void)?
    private var foundVaults: [CKRecordZone.ID: VaultVersion] = [:]
    
    public init() {
        container = CKContainer(identifier: Config.containerIdentifier)
        database = container.privateCloudDatabase
    }
    
    public func checkForVaults(completion: @escaping (Result<[CKRecordZone.ID: VaultVersion], Error>) -> Void) {
        Log("CloudProbe - checking Vault")
        
        self.completion = completion
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.info.rawValue, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        queryOperation.database = database
        
        queryOperation.queuePriority = .veryHigh
        queryOperation.resultsLimit = 2
        
        queryOperation.recordMatchedBlock = recordMatchedBlock
        queryOperation.queryResultBlock = queryResultBlock
        
        database.add(queryOperation)
    }
    
    func recordMatchedBlock(_ recordID: CKRecord.ID, _ result: Result<CKRecord, any Error>) {
        switch result {
        case .success(let record):
            guard record.recordType == RecordType.info.rawValue else {
                return
            }
            let zoneID = recordID.zoneID
            let vaultInfo = InfoRecord(record: record)
            if vaultInfo.version == 1 {
                foundVaults[zoneID] = VaultVersion.v1
            } else if vaultInfo.version == 2 {
                foundVaults[zoneID] = VaultVersion.v2
            } else {
                foundVaults[zoneID] = VaultVersion.v3
            }
        case .failure(let error):
            Log("CloudProbe - Error while checking Vault \(error)")
        }
    }
    
    func queryResultBlock(_ result: Result<CKQueryOperation.Cursor?, any Error>) {
        defer {
            completion = nil
            foundVaults = [:]
        }
        DispatchQueue.main.async {
            
            switch result {
            case .success:
                Log("CloudProbe - Query completed!")
                self.completion?(.success(self.foundVaults))
            case .failure(let error):
                self.completion?(.failure(error))
            }
        }
    }
}
