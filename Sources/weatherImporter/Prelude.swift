//
//  Prelude.swift
//  weatherImporter
//
//  Created by John Connolly on 2019-03-06.
//

import Foundation

precedencegroup MonadicPrecedenceLeft {
    associativity: left
    lowerThan: LogicalDisjunctionPrecedence
    higherThan: AssignmentPrecedence
}

infix operator >>>: MonadicPrecedenceLeft
infix operator |>: MonadicPrecedenceLeft
infix operator <^>: MonadicPrecedenceLeft
infix operator >>-: MonadicPrecedenceLeft
infix operator >=>: MonadicPrecedenceLeft
infix operator <>: MonadicPrecedenceLeft
infix operator <*>: MonadicPrecedenceLeft
infix operator <*: MonadicPrecedenceLeft
infix operator *>: MonadicPrecedenceLeft


prefix operator ^


/// Forward composition h(x) = (f ∘ g)
public func >>> <A,B,C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    return { a in
        return f(a) |> g
    }
}

/// Pipeforward
public func |> <A,B>(a: A, f: @escaping (A) -> B) -> B {
    return f(a)
}

public func identity<A>(_ a: A) -> A {
    return a
}

public func const<A, B>(_ a: A) -> (B) -> A {
    return { _ in a }
}


public func unzurry<A>(_ a: A) -> () -> A {
    return { a }
}

public func zurry<A>(_ function: @escaping () -> A) -> A {
    return function()
}

func <> <A>(f: @escaping (A) -> A, g: @escaping (A) -> A) -> (A) -> A {
    return f >>> g
}

func <> <A: AnyObject>(f: @escaping (A) -> (), g: @escaping (A) -> ()) -> (A) -> () {
    return { a in
        f(a)
        g(a)
    }
}



func prop<Root, Value>(_ kp: WritableKeyPath<Root, Value>)
    -> (@escaping (Value) -> Value)
    -> (Root)
    -> Root {

        return { update in
            { root in
                var copy = root
                copy[keyPath: kp] = update(copy[keyPath: kp])
                return copy
            }
        }
}


prefix func ^ <Root, Value>(kp: KeyPath<Root, Value>) -> (Root) -> Value {
    return get(kp)
}

func get<Root, Value>(_ kp: KeyPath<Root, Value>) -> (Root) -> Value {
    return { root in
        root[keyPath: kp]
    }
}

func their<Root, Value>(
    _ f: @escaping (Root) -> Value,
    _ g: @escaping (Value, Value) -> Bool
    )
    -> (Root, Root)
    -> Bool {
        return { g(f($0), f($1)) }
}


public func flip<A, B, C>(_ f: @escaping (A) -> (B) -> C) -> (B) -> (A) -> C {
    return { b in { a in f(a)(b) } }
}


public func curry<A,B>(_ f: @escaping (A) -> B) -> (A) -> B {
    return f
}

public func curry<A,B,C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in return { b in f(a,b) } }
}

public func curry<A,B,C,D>(_ f: @escaping (A, B, C) -> D) -> (A) -> (B) -> (C) -> D {
    return { a in return { b in return { c in f(a,b,c) } } }
}

public func curry<A,B,C,D,E>(_ f: @escaping (A, B, C, D) -> E) -> (A) -> (B) -> (C) -> (D) -> E {
    return { a in return { b in return { c in return { d in f(a,b,c,d) } } } }
}

public func curry<A,B,C,D,E,F>(_ f: @escaping (A, B, C, D, E) -> F) -> (A) -> (B) -> (C) -> (D) -> (E) -> F {
    return { a in return { b in return { c in return { d in return { e in f(a,b,c,d,e) } } } } }
}

public func curry<A,B,C,D,E,G,H>(_ f: @escaping (A, B, C, D, E, G) -> H) -> (A) -> (B) -> (C) -> (D) -> (E) -> (G) -> H {
    return { a in return { b in return { c in return { d in return { e in { g in return f(a,b,c,d,e,g) } } } } } }
}

