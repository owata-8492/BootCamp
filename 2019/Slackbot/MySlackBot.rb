# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'sinatra'
require 'SlackBot'

class MySlackBot < SlackBot
  def get_town_name(str)
    resxml = Net::HTTP.get(URI.parse("http://zip.cgis.biz/xml/zip.php?zn=#{str}"))
    result = XmlSimple.xml_in(resxml)
    
    if result['result'][5]['result_code'].to_i == 0 || result['result'][8]['result_values_count'].to_i == 0
      town_name = 'エラー！存在しない郵便番号です'
      return town_name
    end
    
    town_name = result['ADDRESS_value'][0]['value'][4]['state'] + result['ADDRESS_value'][0]['value'][5]['city'] + result['ADDRESS_value'][0]['value'][6]['address'] + result['ADDRESS_value'][0]['value'][7]['company']
    town_name = town_name.gsub(/none/,'')
    return town_name
  end
  
  # cool code goes here
end

class Postal_code
  def number
    @number
  end

  def number=(number)
    @number = number
  end
end

slackbot = MySlackBot.new
p_code = Postal_code.new

set :environment, :production

get '/' do
  "SlackBot Server"
end

post '/slack' do
  content_type :json

  #call and response
  if params['text'] == '@Hirobot'
    puts params['text'].length
    return slackbot.naive_respond(params, username: "Hirobot")    
  end

  #repeat after speaker
  if params['text'].start_with?("@Hirobot") && params['text'].include?("「") && params['text'][-5..-1] == '」と言って'
    
    start = params['text'].index("「")
    finish = params['text'].rindex("」と言って")

    start  += 1
    finish -= 1

    params['text'] = params['text'][start..finish]
  
  return slackbot.post_message(params['text']) 
  end

  #set postal_code and answer town_name
  p_code = params['text'][9..15]
  p_code_num = params['text'][9..15].to_i
  smallest_num = 0
  largest_num = 9999999
  if params['text'].include?("@Hirobot") && p_code_num >= smallest_num && p_code_num <= largest_num
    town_name= slackbot.get_town_name(p_code)
    return slackbot.post_message(town_name)
  end
  slackbot.naive_respond(params, username: "Bot")

end
