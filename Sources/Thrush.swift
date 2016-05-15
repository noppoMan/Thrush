//
//  Collections.swift
//  Thrush
//
//  Created by Yuki Takei on 5/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

public struct Thrush {
    
    public static func all<T>(promises: [Promise<T>]) -> Promise<[T]> {
        var canceled = false
        var flags = [Int: T]()
        
        return Promise<[T]> { resolve, reject in
            for e in promises.enumerated() {
                e.element.then {
                    if canceled {
                        return
                    }
                    flags[e.offset] = $0
                    if flags.count == promises.count {
                        let results = flags.sorted(isOrderedBefore: { $0.0 < $1.0 })
                        resolve(results.map{ _, v in v })
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
