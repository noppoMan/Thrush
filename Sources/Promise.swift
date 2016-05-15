//
//  Promise.swift
//  Thrush
//
//  Created by Yuki Takei on 5/10/16.
//  Copyright © 2016 MikeTOKYO. All rights reserved.
//

enum State {
    case Pending
    case Fulfilled
    case Rejected
}

public final class Promise<T> {
    
    public typealias Resolver = (T) -> ()
    
    public typealias Rejector = (ErrorProtocol) -> ()
    
    public var handler: (Resolver, Rejector) -> ()
    
    private var onSuccess: (T) -> () = { _ in }
    
    private var onFailuer: (ErrorProtocol) -> () = { _ in }
    
    private var onFinally: () -> () = { _ in }
    
    private var state: State = .Pending
    
    private var result: T?
    
    private var error: ErrorProtocol?
    
    private var invokeHandler :(() -> ())?
    
    private var initialized = false
    
    private var invoked = false
    
    public init(handler: (Resolver, Rejector) -> ()) {
        self.handler = handler
    }
    
    public static func resolve<T>(_ value: T) -> Promise<T> {
        return Promise<T> { resolve, _ in
            resolve(value)
        }
    }
    
    public func then<X>(_ callback: (T) -> X) -> Promise<X> {
        attemptInitialize()
        attemptInvoke()
        return reserve(callback)
    }
    
    private func reserve<X>(_ callback: (T) -> X) -> Promise<X> {
        let promise = Promise<X>{ [unowned self] resolve, reject in
            switch self.state {
            case .Fulfilled:
                let result: X = callback(self.result!)
                resolve(result)
            case .Rejected:
                reject(self.error!)
            case .Pending:
                self.onSuccess = {
                    resolve(callback($0))
                }
                self.onFailuer = reject
            }
        }
        
        promise.invoke()
        passInvoker(to: promise)
        return promise
    }
    
    public func then<X>(_ callback: (T) -> Promise<X>) -> Promise<X> {
        attemptInitialize()
        attemptInvoke()
        return reserve(callback)
    }
    
    public func reserve<X>(_ callback: (T) -> Promise<X>) -> Promise<X>{
        let promise = Promise<X>{ [unowned self] resolve, reject in
            switch self.state {
            case .Fulfilled:
                self.triggerNext(callback, result: self.result!,resolve: resolve,reject: reject)
            case .Rejected:
                reject(self.error!)
            case .Pending:
                self.onSuccess = { t in
                    self.triggerNext(callback, result: t, resolve: resolve, reject: reject)
                }
                self.onFailuer = reject
            }
        }
        promise.invoke()
        passInvoker(to: promise)
        return promise
    }
    
    public func then<X>(_ promise: Promise<X>) -> Promise<X> {
        return then { _ in promise }
    }
    
    public func reserve<X>(_ promise: Promise<X>) -> Promise<X>{
        return reserve { _ in promise }
    }
    
    public func failure(_ callback: (ErrorProtocol) -> ()) -> Self {
        attemptInvoke()
        if state == .Rejected {
            callback(error!)
        } else {
            onFailuer = callback
        }
        return self
    }
    
    public func finally(_ callback: () -> ()) -> Self  {
        attemptInvoke()
        if state != .Pending {
            callback()
        } else {
            onFinally = callback
        }
        return self
    }
    
    private func invoke() {
        invoked = true
        handler(resolve, reject)
    }
    
    private func attemptInvoke() {
        if !invoked { invoke() }
    }
    
    private func attemptInitialize() {
        if !initialized {
            invokeHandler?()
            initialized = true
        }
    }
    
    private func triggerNext<X>(_ callback: (T) -> Promise<X>, result: T, resolve: (X) -> Void,reject: Rejector) {
        let nextPromise: Promise<X> = callback(result)
        nextPromise.then {
            resolve($0)
            }.failure(reject)
    }
    
    private func passInvoker<X>(to promise: Promise<X>) {
        if let next = self.invokeHandler {
            promise.invokeHandler = next
        } else {
            promise.invokeHandler = { [unowned self] in
                self.invoke()
            }
        }
        
        promise.initialized = self.initialized
    }
    
    private func resolve(_ _result: T) {
        state = .Fulfilled
        result = _result
        onSuccess(_result)
        onFinally()
    }
    
    private func reject(_ e: ErrorProtocol) {
        state = .Rejected
        error = e
        onFailuer(error!)
        onFinally()
    }
}