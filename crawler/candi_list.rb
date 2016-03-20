# 선관위에서 후보 정보 가져오기
# JSON 버전만 만들었어요.
# gem install nokogiri

require 'rubygems'
require 'nokogiri'
require 'json'
require 'net/http'


# 선관위 호스트

NEC_SERVER= 'info.nec.go.kr'
PIC_PREFIX= "http://#{NEC_SERVER}"


#
# 이 URL로 전체 후보를 다 가져올수 있다. 
# 브라우저에서 보면, 시도코드를 선택하게 되어있지만, 
# 시도코드를 0으로 전송하면 전체 시도의 후보를 가져온다.

# 후보 목록 페이지
CANDI_LIST= '/electioninfo/electionInfo_report.xhtml'+
            '?electionId=0020160413&'+
            'requestURI=%2FWEB-INF%2Fjsp%2Felectioninfo%2F0020160413%2Fpc%2Fpcri03_ex.jsp'+
            '&topMenuId=PC&secondMenuId=PCRI03&menuId=PCRI03&'+
            'statementId=PCRI03_%232'+
            '&electionCode=2&cityCode=0&sggCityCode=0&townCode=-1&sggTownCode=0&x=29&y=15'

# 후보 통계 페이지
CANDI_SUM = '/electioninfo/electionInfo_report.xhtml'+
            '?electionId=0020160413'+
            '&requestURI=%2Felectioninfo%2F0020160413%2Fpc%2Fpcri01.jsp'+
            '&topMenuId=PC&secondMenuId=PCRI01&menuId='+
            '&statementId=PCRI01_%232&electionCode=2&cityCode=0&x=37&y=12'




STDERR.puts "retreiving : http://#{NEC_SERVER}#{CANDI_LIST}"
#http = Net::HTTP.new(NEC_SERVER, 80)
#http.read_timeout = 500
list_html   = Net::HTTP.get(NEC_SERVER, CANDI_LIST)
list_doc    = Nokogiri::HTML(list_html)

# 2016 선거구 목록 가져오기
city_list   = {}
city_html   = list_doc.css("select#cityCode")
city_html.css("option").each do |city|
  city_list[city.attribute_nodes[0].to_s] = city.content
end

candi_list  = []

list_doc.css("table#table01").css("tr").each_with_index do |tr, idx|

  candi_array =  tr.css("td")
  h = {}
  if candi_array.size>0
    #STDERR.puts "==="
    #STDERR.puts candi_array.at(3).to_s
    #STDERR.puts candi_array.at(2).children[1].to_s
    #STDERR.puts "==="
    #exit
    photo = candi_array.at(2).children[1].attribute_nodes[1].to_s if candi_array.at(2).children[1]

    # 맨 뒤의 파일이름이 후보의 유니크 아이디인 듯.
    # photo = http://info.nec.go.kr/photo_20160413/Sd1100/Gsg1101/Sgg2110101/Hb100118435/gicho/100118435.jpg

    #h[:id]              = photo.scan( /\/gicho\/(.+)\./).first[0].to_s
    #STDERR.puts candi_array.at(2).to_s
    #STDERR.puts candi_array.at(3).to_s
    h[:id]              = candi_array.at(3).to_s.scan( /popupPreHBJ\((.+)/)[0].to_s.split("'")[3]
    #STDERR.puts h[:id]
    
    # Sd 가 시도를 의미하고, 뒤의 숫자와 select#cityCode 의 숫자를 이용하면 시도이름을 얻을 수 있다.

    h[:city]            = city_list[photo.scan( /\/Sd(.+)\/Gsg/).first[0].to_s] if photo


    h[:district]        = candi_array.at(0).content
    h[:district_long]   = "#{h[:city]}/#{h[:district]}"
    h[:party]           = candi_array.at(1).content
    h[:picture]         = PIC_PREFIX+candi_array.at(2).children[1].attribute_nodes[1] if photo
    h[:name]            = candi_array.at(3).content.strip 
    h[:gender]          = candi_array.at(4).content.strip
    h[:age]             = candi_array.at(5).content      
    h[:address]         = candi_array.at(6).content      
    h[:occupation]      = candi_array.at(7).content   
    h[:education]       = candi_array.at(8).content  
    h[:career]          = candi_array.at(9).content
    h[:criminal_record] = candi_array.at(10).content  
    #h[:raw]            = candi_array
  end
  candi_list << h unless h.empty?

end


# 출력!
puts JSON.pretty_generate(candi_list)


# 통계페이지에서 전체 후보 숫자 가져와서 검증

sum_html = Net::HTTP.get(NEC_SERVER, CANDI_SUM)

Nokogiri::HTML(sum_html).css("table#table01").css("tr").each_with_index do |tr, idx|
  if idx==2
    sum_array =  tr.css("td").children.to_a
    if sum_array[3].content.to_i != candi_list.size
      STDERR.puts "ERROR: candidates : #{sum_array[3].content}, crawled: #{candi_list.size}"

      # 오류 발생!!
      exit
    else
      STDERR.puts "candidates : #{sum_array[3].content}, crawled: #{candi_list.size}"
    end
  end
end


