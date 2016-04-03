# 선관위에서 공약 가져오기
# gem install nokogiri

require 'rubygems'
require 'nokogiri'
require 'json'
require 'net/http'


# 선관위 호스트

NEC_SERVER= 'policy.nec.go.kr'
POLICY_PAGE= '/svc/policy/PolicyList.do?sungerCode=22&page='
PER_PAGE=12

page = 1

# 우리를 위한 정책(이겠죠)
policy_for_korean_people = {}

begin 
	url = POLICY_PAGE+page.to_s
  STDERR.puts "retreiving : http://#{NEC_SERVER}#{url}"
  #http = Net::HTTP.new(NEC_SERVER, 80)
  #http.read_timeout = 500
  list_html   = Net::HTTP.get(NEC_SERVER, url)
  list_doc    = Nokogiri::HTML(list_html)
	#puts list_html

	found = 0
  list_doc.css("ul.candiList").css("div.content").each do |cont|
		necid = cont.css('img')[0].to_s.split('/')[3].split('.')[0]
		#puts necid
		pdf = cont.to_s.split("modalPop('/data/")[1].split("'")[0]
		pdf = "http://"+NEC_SERVER+"/data/"+pdf
		#puts pdf
		found += 1
		policy_for_korean_people[necid] = pdf
	end
	page += 1

end while found == PER_PAGE

puts policy_for_korean_people.to_json
