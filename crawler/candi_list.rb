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
            'requestURI=%2FWEB-INF%2Fjsp%2Felectioninfo%2F0020160413%2Fpc%2Fpcri03_ex.jsp&'+
            'topMenuId=PC&secondMenuId=PCRI03&menuId=PCRI03&'+
            'statementId=PCRI03_%232&'+
            'electionCode=2&cityCode=0&sggCityCode=0&townCode=-1&sggTownCode=0&x=29&y=15'

CANDI_LIST= "/electioninfo/electionInfo_report.xhtml"+
            "?electionId=0020160413&"+
            "requestURI=%2FWEB-INF%2Fjsp%2Felectioninfo%2F0020160413%2Fcp%2Fcpri03.jsp&"+
            "topMenuId=CP&secondMenuId=CPRI03&menuId=CPRI03&"+
            "statementId=CPRI03_%232&"+
            "electionCode=2&sggCityCode=0&cityCode="

CANDI_LISTZ='/electioninfo/electionInfo_report.xhtml?'+
            'electionId=0020160413&'+
            'requestURI=%2FWEB-INF%2Fjsp%2Felectioninfo%2F0020160413%2Fcp%2Fcpri03.jsp&'+
            'topMenuId=CP&secondMenuId=CPRI03&menuId=CPRI03&'+
            'statementId=CPRI03_%237&'+
            'electionCode=7&cityCode=-1'


# 후보 통계 페이지
CANDI_SUM = '/electioninfo/electionInfo_report.xhtml'+
            '?electionId=0020160413'+
            '&requestURI=%2Felectioninfo%2F0020160413%2Fpc%2Fpcri01.jsp'+
            '&topMenuId=PC&secondMenuId=PCRI01&menuId='+
            '&statementId=PCRI01_%232&electionCode=2&cityCode=0&x=37&y=12'

#cities = [1100, 2600, 2700, 2800, 2900, 3000, 3100, 5100, 4100, 4200, 4300, 4400, 4500, 4600, 4700, 4800, 4900]
cities = {'1100'=> "서울특별시", '2600'=> "부산광역시", '2700'=> "대구광역시", 
          '2800'=> "인천광역시", '2900'=> "광주광역시", '3000'=> "대전광역시", 
          '3100'=> "울산광역시", '5100'=> "세종특별자치시", '4100'=> "경기도", 
          '4200'=> "강원도",     '4300'=> "충청북도", '4400'=> "충청남도", 
          '4500'=> "전라북도",   '4600'=> "전라남도", '4700'=> "경상북도", 
          '4800'=> "경상남도", '4900'=> "제주특별자치도", '9999'=>'비례대표'}

candi_list  = []

cities.each do |city, cityname|

  url = CANDI_LIST+city.to_s

  if city=='9999'
    url = CANDI_LISTZ
  end
  

  STDERR.puts "retreiving : http://#{NEC_SERVER}#{url}"
  #http = Net::HTTP.new(NEC_SERVER, 80)
  #http.read_timeout = 500
  list_html   = Net::HTTP.get(NEC_SERVER, url)
  list_doc    = Nokogiri::HTML(list_html)

  # 2016 선거구 목록 가져오기

  list_doc.css("table#table01").css("tr").each_with_index do |tr, idx|

    candi_array =  tr.css("td")
    h = {}
    if candi_array.size>0
      next if candi_array.to_s.include?('검색된 결과가 없습니다.')
      #STDERR.puts candi_array
      #exit

      # 맨 뒤의 파일이름이 후보의 유니크 아이디인 듯.
      # photo = http://info.nec.go.kr/photo_20160413/Sd1100/Gsg1101/Sgg2110101/Hb100118435/gicho/100118435.jpg

      #h[:id]              = photo.scan( /\/gicho\/(.+)\./).first[0].to_s
      #STDERR.puts candi_array.at(2).to_s
      #STDERR.puts candi_array.at(3).to_s
      h[:id]              = candi_array.at(4).to_s.scan( /popupHBJ\((.+)/)[0].to_s.split("'")[3]
      #STDERR.puts h[:id]
      #exit
      
      # Sd 가 시도를 의미하고, 뒤의 숫자와 select#cityCode 의 숫자를 이용하면 시도이름을 얻을 수 있다.

      h[:city]            = cityname


      h[:district]        = candi_array.at(0).content
      h[:district_long]   = "#{h[:city]}/#{h[:district]}"

      if city=='9999'
        photo = candi_array.at(1).children[1].attribute_nodes[1].to_s if candi_array.at(1).children[1]
        h[:order]           = candi_array.at(3).content
        h[:party]           = candi_array.at(2).content.split('(')[0]
        h[:picture]         = PIC_PREFIX+candi_array.at(1).children[1].attribute_nodes[1] if photo
        if h[:picture].nil? or h[:picture].strip.size<=1
          STDERR.puts "1"
          STDERR.puts candi_array
          STDERR.puts photo
          STDERR.puts h
          #exit
        end
      else
        photo = candi_array.at(1).children[1].attribute_nodes[1].to_s if candi_array.at(1).children[1]
        h[:order]           = candi_array.at(2).content
        h[:party]           = candi_array.at(3).content
        h[:picture]         = PIC_PREFIX+candi_array.at(1).children[1].attribute_nodes[1] if photo
        if candi_array.at(4).content.strip=='장지웅(張智雄)'
        #if h[:picture].nil? or h[:picture].strip.size<=1
          STDERR.puts "=="+candi_array.at(0)+"=="
          STDERR.puts candi_array.at(0)
          STDERR.puts "2"
          STDERR.puts candi_array
          STDERR.puts photo
          STDERR.puts h
          #exit
        end
      end
      h[:name]            = candi_array.at(4).content.strip 
      h[:gender]          = candi_array.at(5).content.strip
      h[:age]             = candi_array.at(6).content      
      h[:address]         = candi_array.at(7).content      
      h[:occupation]      = candi_array.at(8).content   
      h[:education]       = candi_array.at(9).content  
      h[:career]          = candi_array.at(10).content
      h[:asset]           = candi_array.at(11).content.gsub(',','')
      h[:military]        = candi_array.at(12).content  
      h[:tax]             = candi_array.at(13).content.gsub(',','')
      h[:tax_not_thisyear]= candi_array.at(14).content.gsub(',','')
      h[:tax_not]         = candi_array.at(15).content.gsub(',','')
      h[:criminal_record] = candi_array.at(16).content  

      #h[:raw]            = candi_array
    end
    candi_list << h unless h.empty?
  end
end


# 출력!
puts JSON.pretty_generate(candi_list)
