require "json"

module Response
  class Toggle
    JSON.mapping({
      idm: String
    })
  end

  class Result
    JSON.mapping({
      events: Array(Event),
    })
  end

  class Event
    JSON.mapping({
      type: String,
      timestamp: Int64,
      source: Source,
      replyToken: { type: String, nilable: true },
      message: { type: Message, nilable: true },
    })
  end

  class Source
    JSON.mapping({
      type: String,
      userId: { type: String, nilable: true },
      groupId: { type: String, nilable: true },
      roomId: { type: String, nilable: true },
    })
  end

  class Message
    JSON.mapping({
      id: String,
      type: String,
      text: { type: String, nilable: true },
      fileName: { type: String, nilable: true },
      fileSize: { type: String, nilable: true },
      title: { type: String, nilable: true },
      address: { type: String, nilable: true },
      latitude: { type: Float64, nilable: true },
      longitude: { type: Float64, nilable: true },
      packageId: { type: String, nilable: true },
      stickerId: { type: String, nilable: true },
    })
  end

  class Reply
    JSON.mapping({
      replyToken: String,
      messages: Array(ReplyMessage),
    })

    def initialize(@replyToken : String, @messages : Array(ReplyMessage))
    end
  end

  class Push
    JSON.mapping({
      to: String,
      messages: Array(ReplyMessage),
    })

    def initialize(@to : String, @messages : Array(ReplyMessage))
    end
  end

  class ReplyMessage
    JSON.mapping({
      type: String,
      text: { type: String, nilable: true },
      fileName: { type: String, nilable: true },
      fileSize: { type: String, nilable: true },
      title: { type: String, nilable: true },
      address: { type: String, nilable: true },
      latitude: { type: Float64, nilable: true },
      longitude: { type: Float64, nilable: true },
      packageId: { type: String, nilable: true },
      stickerId: { type: String, nilable: true },
    })
    def initialize(@type : String)
    end
    def add_text(@text : String)
      self
    end
  end

  class Cardid
    JSON.mapping({
      cardid: String,
    })
  end

  class CardNames
    JSON.mapping({
      cardNames: Array(CardName),
    })
  end

  class CardName
    JSON.mapping({
      idm: String,
      name: String,
    })
  end
end
