//
//  main.swift
//  weatherImporter
//
//  Created by John Connolly on 2019-03-06.
//

import Foundation

let saveLocation = "/Users/johnconnolly/Downloads/ClimateData"

struct RequestResource {
    let req: URLRequest
    let fileName: String
}

func construct(year: Int, month: Int) -> RequestResource {
    let url = "http://climate.weather.gc.ca/prods_servs/cdn_climate_summary_report_e.html?intYear="
        + year.description
        + "&intMonth="
        + month.description
        + "&prov=NS&dataFormat=csv&btnSubmit=Download+data"
    return RequestResource(req: URLRequest(url: URL(string: url)!), fileName: year.description + "-" + month.description)
}

let allRequests = (1...12).flatMap { month in
    (1960...2018).map(curry(construct(year:month:))).map { $0(month) }
}


let utf8 = flip(curry(String.init(data:encoding:)))(.utf8)

func unwrapOrDie<T>(_ t: T?) -> T {
    guard let t = t else {
        fatalError("Could not unwrap")
    }
    return t
}

func log<T>(_ item: T) -> T {
    print(item)
    return item
}

extension String {
    var lines: [[String]] {
        return self.components(separatedBy: "\n").map { $0.components(separatedBy: ",") }
    }
}

func trimLegend(_ lines: [[String]]) -> [[String]] {
    return lines.filter { $0.count > 4 }
}

func save(name: String, csv: [[String]]) {
    let csvS = csv.reduce(into: "") { (result, next) in
        result += next.joined(separator: ",")
        result += "\n"
    }
    let data = Data(csvS.utf8)
    var url = URL(fileURLWithPath: saveLocation)
    url.appendPathComponent("\(name).csv")
    try! data.write(to: url)
}

func make(request: RequestResource) -> Future<()> {
    return WebService()
        .load(request.req)
        .map(utf8 >>> unwrapOrDie)
        .map(^\.lines)
        .map(trimLegend)
        .map(curry(save)(request.fileName))
}


allRequests.map(make(request:)).flatten().map { _ in
    print("Done!")
}

//makeRequest()



RunLoop.main.run()
