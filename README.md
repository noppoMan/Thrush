# Thrush
A lightweight promise implementation for Swift


## Usage

```swift

func increment(n: Int) -> Int {
  return n + 1
}

_ = Promise<Int> { resolve, reject in
    resolve(1)
    }
    .then(increment)
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
        print($0) // 5
    }
```

## Rejection and Finally

```swift

_ = Promise<Int> { resolve, reject in
        resolve(1)
    }
    .then { _ -> Promise<Int> in
        return Promise<Int> { _, reject in
            reject(SomethingError)
        }
    }
    .`catch` {
        print($0)
    }
    .finally {
        print("Everything is Done")
    }
```


## Collection

### all

The `Thrush.all(promises: [Promise<T>])` method returns a promise that resolves when all of the promises in the promises argument have resolved, or rejects with the reason of the first passed promise that rejects.

**This is performed as parallel**

```swift

let p1 = Promise<Int> { resolve, _ in
    asyncSomething {
      resolve(1)
    }
}

let p2 = Promise<Int> { resolve, _ in
    asyncSomething {
      resolve(1)
    }
}

Thrush.all(promises: [p1, p2]).then {
    $0.reduce(0, combine: +) //2
}
```


### map

The `Thrush.map(promises: [Promise<T>])` method returns a promise that resolves when all of the promises in the promises argument have resolved, or rejects with the reason of the first passed promise that rejects.

**This is performed as in order**

```swift

let p1 = Promise<Int> { resolve, _ in
    asyncSomething {
      sleep(1) // p2 will be waited
      resolve(1)
    }
}

let p2 = Promise<Int> { resolve, _ in
    asyncSomething {
      resolve(1)
    }
}

Thrush.map(promises: [p1, p2]).then {
    $0.reduce(0, combine: +) //2
}
```


## Package.swift

```swift
import PackageDescription

let package = Package(
    name: "MyApp",
    dependencies: [
        .Package(url: "https://github.com/noppoMan/Thrush.git", majorVersion: 0, minor: 1),
    ]
)
```


## Licence

Thrush is released under the MIT license. See LICENSE for details.
