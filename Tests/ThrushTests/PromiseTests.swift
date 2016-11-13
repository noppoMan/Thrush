//
//  ThrushTests.swift
//  Thrush
//
//  Created by Yuki Takei on 5/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

import XCTest
@testable import Thrush


enum TestError: Error {
    case Something
}

class PromiseTests: XCTestCase {
    static var allTests: [(String, (PromiseTests) -> () throws -> Void)] {
        return [
                   ("testPromise", testPromise),
                   ("testAll", testAll),
                   ("testMap", testMap)
        ]
    }
    
    func testPromise(){
        _ = Promise<Int> { resolve, reject in
            resolve(1)
            }
            .then { (t: Int) -> Int in
                return t+1
            }
            .then { (t: Int) -> Promise<Int> in
                return Promise<Int>.resolve(t+1)
            }
            .then { (t: Int) -> Promise<Int> in
                return Promise<Int> { resolve, _ in
                    resolve(t+1)
                }
            }
            .then {
                XCTAssertEqual(4, $0)
        }
        
        
        _ = Promise<Int> { resolve, reject in
            resolve(1)
            }
            .then { _ -> Promise<Int> in
                return Promise<Int> { _, reject in
                    reject(TestError.Something)
                }
            }
            .then { _ in
                XCTFail("Never called")
            }
            .`catch` {
                XCTAssertNotNil($0)
        }
    }
    
    func testAll() {
        let p1 = Promise<Int> { resolve, _ in
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                resolve(1)
            }
        }
        
        _ = Thrush.all(promises: [p1, Promise<Int>.resolve(2)]).then {
            XCTAssertEqual([1, 2], $0)
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        
        CFRunLoopRun()
    }
    
    func testMap(){
        let p1 = Promise<Int> { resolve, _ in
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                resolve(1)
            }
        }
        
        _ = Thrush.map(promises: [p1, Promise<Int>.resolve(2)]).then {
            XCTAssertEqual([1, 2], $0)
            CFRunLoopStop(CFRunLoopGetCurrent())
        }
        
        CFRunLoopRun()
    }
}

