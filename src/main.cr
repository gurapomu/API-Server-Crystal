require "json"
require "./json_map"
require "./params"
require "http/server"

PUSH_ENDPOINT = "https://api.line.me/v2/bot/message/push"
REPLY_ENDPOINT = "https://api.line.me/v2/bot/message/reply"
CARD_NAMES_JSON = "../resource/cardnames.json"

def get_handler(request : HTTP::Request)
  puts "get request"
  puts request.query
  200
end

def post_handler(request : HTTP::Request, list : Hash)
  puts "post request"
  body = request.body

  if body.is_a?(IO)
    if request.path == "/nfcpush"
      return nfcpush(Response::Cardid.from_json(body.gets_to_end).cardid, list)
    elsif request.path == "/bot/callback"
      event = Response::Result.from_json(body.gets_to_end).events[0]
      return callback(request, event, list)
    else
      return 404
    end
  else
    return 400
  end
end

def nfcpush(idm : String, list : Hash)
  cardNames = Response::CardNames.from_json(File.read(CARD_NAMES_JSON)).cardNames
  qual = cardNames.select {|c| c.idm == idm}
  text = ""
  if qual.size != 0
    text = qual[0].name
  else
    text = "未登録のユーザー"
  end
  list[idm] = false if !list.has_key?(idm)
  text += list[idm]? ? "さんが退勤しました" : "さんが出勤しました"
  list[idm] = !list[idm]
  puts text
  push = Response::Push.new(Params::GROUP_ID, [Response::ReplyMessage.new("text").add_text(text)]).to_json
  HTTP::Client.post(PUSH_ENDPOINT,
                    headers: HTTP::Headers{
                      "Content-Type" => "application/json",
                      "Authorization" => "Bearer {#{Params::ACCESS_TOKEN}}"
                    },
                    body: push)
  return 200
end

def callback(request : HTTP::Request, event : Response::Event, list : Hash)
  message = event.message
  if message.is_a?(Response::Message)
    puts "message event!"
    if event.source.groupId.is_a?(String)
      puts "Group ID:#{event.source.groupId}"
      text = message.text
      replyToken = event.replyToken
      if text.is_a?(String) && replyToken.is_a?(String)
        replyMessage(replyToken, text, list)
      end
    elsif event.source.roomId.is_a?(String)
      puts "Room ID:#{event.source.roomId}"
    else
      puts "User ID:#{event.source.userId}"
    end
  else
    puts "other event!"
  end
  return 200
end

def replyMessage(replyToken : String, message : String, list : Hash)
  if message.includes?("@カイケツ出退勤管理クン")
    list = list.select {|k, v| v == true}
    text = list.size != 0 ? "#{list.size}人がオフィスにいます\n" : "オフィスには誰もいません"
    cardNames = Response::CardNames.from_json(File.read(CARD_NAMES_JSON)).cardNames
    list.map {|k, v| cardNames.select {|c| c.idm == k}.size != 0 ? cardNames.select {|c| c.idm == k}[0].name : "未登録のユーザー"}.each {|e| text += "#{e} "}
    puts text
    reply = Response::Reply.new(replyToken, [Response::ReplyMessage.new("text").add_text(text)]).to_json
    HTTP::Client.post(REPLY_ENDPOINT,
                      headers: HTTP::Headers{
                        "Content-Type" => "application/json",
                        "Authorization" => "Bearer {#{Params::ACCESS_TOKEN}}"
                      },
                      body: reply)
  else
    puts "else"
  end
end

list = Hash(String, Bool).new

server = HTTP::Server.new(8080) do |context|
  code = Int32.new(0)
  if context.request.method == "GET"
    code = get_handler(context.request)
  elsif context.request.method == "POST"
    code = post_handler(context.request, list)
  end

  if code != 200
    context.response.respond_with_error("message", code)
  else
    context.response.content_type = "text/plain"
    context.response.print "Hello world, got #{context.request.path}!"
  end
end

puts "Listening on http://0.0.0.0:8080"
server.listen
