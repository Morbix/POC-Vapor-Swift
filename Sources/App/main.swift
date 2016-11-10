import Vapor
import Ji
import Foundation

class Event {
  var date: String?
  var place: String?
  var status: String?
  var description: String?
}

func isDate(_ value: String) -> Bool {
  let dateFormatter = DateFormatter()
  dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
  let date = dateFormatter.date(from: value)
  if let _ = date {
    return true
  }
  return false
}

enum InfoType: Int {
  case place = 1
  case status = 2
  case description = 3
}

func getInfo(nodes: [JiNode], index: Int, infoType: InfoType) -> String? {
  if nodes.count > index + 1 {
    let value = nodes[index + infoType.rawValue].content!
    if !isDate(value) {
      return value
    }
  }

  return nil
}

let correiosUrl = "http://websro.correios.com.br/sro_bin/txect01%24.QueryList?P_LINGUA=001&P_TIPO=001&P_COD_UNI="
let validCode = "PN287778349BR"

let drop = Droplet()

drop.get("hello") { request in
  return "Hello, world!"
}

drop.get("search", ":code") { request in
  guard let code = request.parameters["code"]?.string else {
    throw Abort.badRequest
  }

  guard let jiDoc = Ji(htmlURL: URL(string: correiosUrl + code)!) else {
    throw Abort.badRequest
  }
  guard let tableNode = jiDoc.xPath("//table")?.first else {
    throw Abort.badRequest
  }
  let tdNodes = tableNode.xPath("//td")

  let trackValues = tdNodes.reduce("===") { result, td in
    return "\(result), \(td.content!)"
  }

  var events: Array<Event> = []

  for (index, td) in tdNodes.enumerated() {
    if isDate(td.content!) {
      var event = Event()
      event.date = td.content!

      event.place = getInfo(nodes: tdNodes, index: index, infoType: InfoType.place)
      event.status = getInfo(nodes: tdNodes, index: index, infoType: InfoType.status)

      events.append(event)
    }
  }

  let dateValues = events.map { event in
    return event.status!
  }.debugDescription

  return trackValues + "\n\n\n" + dateValues
}



drop.get { req in
    return try drop.view.make("welcome", [
    	"message": drop.localization[req.lang, "welcome", "title"]
    ])
}

drop.resource("posts", PostController())

drop.run()
