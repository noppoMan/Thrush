//
//  Collections.swift
//  Thrush
//
//  Created by Yuki Takei on 5/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

public struct Thrush {
    
    public static func all<T>(promises: [Promise<T>]) -> Promise<[T]> {
        var results = [T]()
        var canceled = false
        
        return Promise<[T]> { resolve, reject in
            for promise in promises {
                promise.then {
                    if canceled {
                        return
                    }
                    results.append($0)
                    if results.count == promises.count {
                        resolve(results)
                    }
                }
                .failure {
                    if !canceled {
                        canceled = true
                        reject($0)
                    }
                }
            }
        }
    }
    
    public static func map<T>(promises: [Promise<T>]) -> Promise<[T]> {
        return Promise<[T]> { resolve, reject in
            var results = [T]()
            var index = 0
            func _series(_ current: Promise<T>) {
                current.then {
                    results.append($0)
                    if results.count == promises.count {
                        resolve(results)
                        return
                    }
                    index += 1
                    _series(promises[index])
                    }
                    .failure {
                        reject($0)
                    }
            }
            _series(promises[index])
        }
    }
    
}
