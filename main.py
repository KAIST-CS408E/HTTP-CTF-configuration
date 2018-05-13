#!/usr/bin/python
import io
from shutil import copyfile
import json

def fileRead(filePath):
    f = io.open(filePath, 'r')
    return f.read()

TEMPLATE_FILE = 'install.template.sh'
CTFCONFIG_JSON = 'ctf.json'
FIREBASECONFIG_JSON = 'firebaseConfig.json'
TEAMCONFIG_JSON = 'teamConfig.json'
FIREBASEINIT_JSON = 'firebase.init.js'
DBSETTING_PY = 'setting.py'
NOTIFICIATIONCONFIG_JSON = 'notificationConfig.rb'
FINAL_FILE = 'install.sh'

def setNameSpace(teamConfig, ctfConfig):
    with open(teamConfig, 'r') as file :
        j = json.load(file)
        teamSize = len(j['teams'])
        teamList = []
        for i in range(1, 1+teamSize):
            teamList.append({
                "name": "team%d" % (i),
                "namespace": "team%d" % (i)
            })
    with open(ctfConfig, 'r') as file:
        fs = json.load(file)
        fs["teams"] = teamList
    with open(ctfConfig, 'w') as file:
        json.dump(fs, file, indent=4, separators=(',', ': '))

def getAPISecretKey(teamConfig):
    with open(teamConfig, 'r') as file :
        j = json.load(file)
        return j['api_secret']

def getName(teamConfig):
    with open(teamConfig, 'r') as file :
        j = json.load(file)
        return j['name'].replace(" ", "\ ")

def getAPIBaseUrl(teamConfig):
    with open(teamConfig, 'r') as file :
        j = json.load(file)
        return j['api_base_url']

def getDBInfo(dbSetting):
    with open(dbSetting, 'r') as file :
        ret = {}
        for l in file:
            l = l.replace('\n', '').split("=")
            key = l[0].strip()
            value = l[1].strip().replace('"','')
            ret[key] = value
        return ret

def getNotificationInfo(notificationConfig):
    with open(notificationConfig, 'r') as file :
        ret = {}
        for l in file:
            if '{' in l or '}' in l:
                continue
            l = l.split("=>")
            key = ''.join(e for e in l[0].strip() if e.isalnum())
            value = l[1].strip().replace(',','').replace('\'','')
            ret[key] = value
        return ret

if __name__ == '__main__':
    from shutil import copyfile
    copyfile(TEMPLATE_FILE, FINAL_FILE)
    setNameSpace(TEAMCONFIG_JSON, CTFCONFIG_JSON)
    with open(TEMPLATE_FILE, 'r') as file :
        filedata = file.read()
    noti = getNotificationInfo(NOTIFICIATIONCONFIG_JSON)
    db = getDBInfo(DBSETTING_PY)
    api_secret = getAPISecretKey(TEAMCONFIG_JSON)
    api_base_url = getAPIBaseUrl(TEAMCONFIG_JSON)
    ctf_name = getName(TEAMCONFIG_JSON)

    filedata = filedata.replace('{* ctf.json *}', fileRead(CTFCONFIG_JSON)).\
        replace('{* firebaseConfig.json *}', fileRead(FIREBASECONFIG_JSON)).\
        replace('{* teamConfig.json *}', fileRead(TEAMCONFIG_JSON)).\
        replace('{* firebase.init.js *}', fileRead(FIREBASEINIT_JSON)).\
        replace('{* setting.py *}', fileRead(DBSETTING_PY)).\
        replace('{* API_BASE_URL *}', api_base_url).\
        replace('{* API_SECRET_KEY *}', api_secret).\
        replace('{* ctf_name *}', ctf_name).\
        replace('{* NOTI_TIMEOUT *}', noti['timeout']).\
        replace('{* NOTI_THRES *}', noti['threshold']).\
        replace('{* NOTI_BACKOFF *}', noti['backoff']).\
        replace('{* DOCKER_DISTRIBUTION_SERVER *}', db['DOCKER_DISTRIBUTION_SERVER']).\
        replace('{* DOCKER_DISTRIBUTION_PORT *}', db['DOCKER_DISTRIBUTION_PORT']).\
        replace('{* MYSQL_DATABASE_USER *}', db['MYSQL_DATABASE_USER']).\
        replace('{* MYSQL_DATABASE_PASSWORD *}', db['MYSQL_DATABASE_PASSWORD'])
    with open(FINAL_FILE, 'w') as file:
        file.write(filedata)