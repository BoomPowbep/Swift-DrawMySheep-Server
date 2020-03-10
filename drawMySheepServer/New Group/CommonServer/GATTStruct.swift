//
//  GATTStruct.swift
//  BLEClient
//
//  Created by AL on 27/02/2020.
//  Copyright © 2020 AL. All rights reserved.
//

import Foundation

let GATTStruct = """
    {
        "peripheralName": "###",
        "Services": [
            {
                "name" : "ServiceBLE",
                "uuid" : "EE25B7B6-7798-4749-8B12-734CFBC5CAA9",
                "isPrimary" : true,
                "characteristics": [
                    {
                        "name" : "Auth",
                        "uuid" : "499D456C-8691-4D00-87E2-8A34FB7551A3",
                        "properties" : [2,8],
                        "permissions": [1,2]
                    },
                    {
                        "name" : "Data",
                        "uuid" : "0E3A638E-B390-4610-BB9E-048A68BDD209",
                        "properties" : [8],
                        "permissions": [2]
                    }
                ]
            }
        ]
    }

"""
