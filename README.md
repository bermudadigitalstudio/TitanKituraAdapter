# TitanKituraAdapter
Implements the ServerDelegate protocol for Titan, allowing usage of Titan with Kitura's server.

## Getting started

TitanKituraAdapter depends on [Kitura-net](https://github.com/IBM-Swift/Kitura-net), the engine that powers Kitura, so you don't really need to do much besides importing this package. Here's a simple example in your main.swift

```swift
import Titan
import TitanKituraAdapter

let titanApp = Titan()

titanApp.get("/") {
  return "Hello world"
}

TitanKituraAdapter.serve(titanApp.app, on: 8000)
```

or if you're using the Titan top level sugar:

```swift
import Titan
import TitanKituraAdapter

get("/") {
  return "Hello world"
}

TitanKituraAdapter.serve(TitanApp, on: 8000)
```

## How?

Kitura's webserver interacts with an application through the [`ServerDelegate` protocol](https://github.com/IBM-Swift/Kitura-net/blob/master/Sources/KituraNet/Server/ServerDelegate.swift). `TitanKituraAdapter` implements a `TitanServerDelegate` which conforms to this protocol. The `serve` function is only a few lines long and [does pretty much the same thing]("./Sources/TitanKituraAdapter.swift") that [Kitura's main interface to starting and running servers does](https://github.com/IBM-Swift/Kitura/blob/master/Sources/Kitura/Kitura.swift#L38-L95)

