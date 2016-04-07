# -*- coding: utf-8 -*-
#########################################
# 선관위에서 공약 가져오기
# original ruby code by jinto
# https://github.com/everywish/itelec2016/blob/master/crawler/policy.rb
#
# python version  by antizm
#########################################

from __future__ import print_function
from bs4 import BeautifulSoup
from collections import OrderedDict
from time import sleep
import codecs
import json
import os
import pprint
import requests
import sys


# 선관위 호스트
NEC_SERVER= 'policy.nec.go.kr'
POLICY_PAGE= '/svc/policy/PolicyList.do?sungerCode=22&page='
PER_PAGE=12

headers={
    'User-agent': 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:45.0) Gecko/20100101 Firefox/45.0',
    'Accept-Language': 'ko-KR,ko;q=0.8,en-US;q=0.5,en;q=0.3',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive'
}

def policy(argv):
    # 우리를 위한 정책(이겠죠)

    policy_for_korean_people = OrderedDict()
    #for page in range(1, PER_PAGE+1):
    page=1
    while True:
        url = POLICY_PAGE+str(page)
        addr = 'http://{NEC_SERVER:s}{url:s}'.format(NEC_SERVER=NEC_SERVER, url=url)
        print('retreiving :', addr)
        html=requests.get(addr, headers=headers).text
        soup=BeautifulSoup(html)
        found=0
        for idx, member_tag in enumerate(soup.select('.candiList li'), start=1):
            necid = member_tag.select('.content img')[0]['src'].split('/')[3].split('.')[0]

            name = member_tag.select('.content .text dl dt span')[0].text.strip()

            entry_tag = member_tag.select('.content .text dl dt')[0]
            [s.extract() for s in entry_tag('span')]
            entry = entry_tag.text.strip().replace('\r\n', ' ').replace('\t', '')

            party = member_tag.select('.content .text dl dd')[0].text.strip()
            sector = member_tag.select('.content .text dl dd')[1].text.strip()

            link= member_tag.select('.blueBtn a')[0]['href']

            s=link.replace('javascript:modalPop(','').replace(');','')
            l=[i.replace("'","") for i in s.split(', ')]

            policy_for_korean_people[necid]={
                'url':'http://'+NEC_SERVER+l[0], 
                'entry':entry, 
                'name':name, 
                'party':party, 
                'sector':sector}

            found+=1
        if found != PER_PAGE:
            break
        page+=1
        sleep(0.5)

    with codecs.open('data.json', 'w', encoding='utf-8') as fp:
        json.dump(policy_for_korean_people, fp, indent=2, sort_keys=False, ensure_ascii=False)

    pp = pprint.PrettyPrinter(indent=4)
    pp.pprint(policy_for_korean_people)
    return policy_for_korean_people


def download_file(url, folder=None):
    local_filename = url.split('/')[-1]
    if folder:
        if not os.path.exists(folder):
            print("MKDIR :", folder)
            os.makedirs(folder)     
    # NOTE the stream=True parameter
    r = requests.get(url, stream=True)
    index=0
    with open(folder + local_filename, 'wb') as f:
        for chunk in r.iter_content(chunk_size=1024): 
            if chunk: # filter out keep-alive new chunks
                f.write(chunk)
                f.flush() # commented by recommendation from J.F.Sebastian
                if index % 100 == 0:
                    print('.', end='')
                index+=1
#        f.flush()
    print('')
    return local_filename


if __name__ == '__main__':
    try:
        folder='./data/'
        policy=policy(sys.argv[1:])
        for i in policy:
            f=download_file(policy[i]['url'], folder)
            new_filename = '{0}_{1}_{2}_{3}_{4}_{5}'.format(i, policy[i]['name'], policy[i]['party'], policy[i]['sector'], policy[i]['entry'], f)
            try:
                os.rename(folder+f, folder+new_filename)
                print('{NECID:s} : {SAVED_FILE:s} => {NEW_FILE:s}'.format(NECID=i, SAVED_FILE=f, NEW_FILE=new_filename))
            except Exception as e:
                print('Exception :', str(e))
            sleep(0.5)

    except Exception as e:
        print('Exception :', str(e))
