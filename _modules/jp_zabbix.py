# -*- coding: utf-8 -*-

"""
A wrapper for disk.usage
"""

from pyzabbix import ZabbixAPI
import logging
import json
import random

log = logging.getLogger(__name__)

####################
##      ZAPI      ##
####################

def _get_zapi(connection_user=None,
              connection_password=None,
              connection_url=None):
    log.debug("JP_ZABBIX: _get_zapi : START")
    if not connection_user:
        connection_user = __pillar__['zabbix3']['configuration']['connection_user']
        connection_password = __pillar__['zabbix3']['configuration']['connection_password']
        connection_url = __pillar__['zabbix3']['configuration']['connection_url']

    zapi = None
    try:
        zapi = ZabbixAPI(connection_url)
        zapi.login(connection_user, connection_password)
    except Exception as e:
        log.warning(str(e))
        pass

    log.debug("JP_ZABBIX: _get_zapi : START")
    return zapi

###############
## USERGROUP ##
###############

def usergroup_create(name,
                     permission,
                     **kwargs):
    log.debug('JP_ZABBIX : usergroup_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    usergroupget = usergroup_get(name)
    if len(usergroupget) == 0:
        try:
            for hid in zapi.hostgroup.get():
                zapi.usergroup.create(name=name,
                                      rights={'permission':permission,
                                              'id':hid['groupid']},
                                 **kwargs)
        except Exception as e:
            log.warning(str(e))
            pass
    else:
        try:
            for hid in zapi.hostgroup.get():
                zapi.usergroup.update(usrgrpid=usergroupget[0]['usrgrpid'],
                                      rights={'permission':permission,
                                              'id':hid['groupid']},
                                      **kwargs)
        except Exception as e:
            log.warning(str(e))
            pass
    log.debug('JP_ZABBIX : usergroup_create : END')

def usergroup_get(name,
                  **kwargs):
    log.debug('JP_ZABBIX : usergroup_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        result = zapi.usergroup.get(search={"name":name})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : usergroup_get : END')
    return result


####################
##      USER      ##
####################

def user_create(alias,
                psswd,
                usrgrps,
                type,
                usergroup=None,
                theme="default",
                **connection_args):
    log.debug('JP_ZABBIX : user_create : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    if not user_exists(alias, **connection_args):
        result = 'User Already exists !!'
        try:
            log.debug('try adding user: ' + alias)
            log.debug(usrgrps)
            if usergroup != None:
                usrgrps[0]['usrgrpid'] = usergroup_get(usergroup)[0]['usrgrpid']
            result = zapi.user.create(alias=alias,
                                      passwd=psswd,
                                      usrgrps=usrgrps,
                                      theme=theme,
                                      type=type)
        except Exception as e:
            log.error(str(e))
            pass
    else:
        user_update(alias,
                    psswd,
                    usrgrps,
                    type,
                    theme=theme,
                    usergroup=usergroup,
                    **connection_args)
    log.debug('JP_ZABBIX : user_create : END')
    return

def user_update(alias,
                psswd,
                usrgrps,
                type,
                theme="default",
                force = False,
                usergroup=None,
                **connection_args):
    log.debug('JP_ZABBIX : user_update : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = "ERROR"
    if force or user_exists(alias, **connection_args):
        try:
            if usergroup != None:
                usrgrps['usrgrpid'] = usergroup_get(usergroup)[0]['usrgrpid']
            log.debug('UPDATING user: ' + alias)
            userid = user_get(alias, **connection_args)[0]['userid']
            log.debug("USERID: "+userid)
            result = zapi.user.update(userid=userid,
                                      passwd=psswd,
                                      usrgrps=usrgrps,
                                      type=type,
                                      theme=theme)
        except Exception as e:
            log.warning(str(e))
            pass

    log.debug('JP_ZABBIX : user_update : END')
    return

def user_addmedia(alias,
                  **kwargs):
    log.info('JP_ZABBIX : user_addmedia : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = "ERROR"
    if user_exists(alias) and ('medias' in kwargs):
        try:
            doit = True
            medias = user_getmedia(alias)
            for m in medias:
                if m['sendto'] == kwargs['medias']['sendto']:
                    doit = False
            if doit:
                log.debug('Addmedia to user: ' + alias)
                userid = user_get(alias)[0]['userid']
                log.debug("USERID: "+userid)
                result = zapi.user.addmedia(users={'userid': userid},
                                            **kwargs)
        except Exception as e:
            log.warning(str(e))
            pass
    log.info('JP_ZABBIX : user_addmedia : END')

def user_getmedia(alias,
                  **kwargs):
    log.info('JP_ZABBIX : user_getmedia : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    if user_exists(alias):
        try:
            log.debug('Addmedia to user: ' + alias)
            userid = user_get(alias)[0]['userid']
            result = zapi.usermedia.get(usersids=userid)
        except Exception as e:
            log.warning(str(e))
            pass
    log.info('JP_ZABBIX : user_getmedia : END')
    return result

def user_exists(user,
                **connection_args):
    log.debug('JP_ZABBIX : user_exists : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = []
    try:
        log.debug('Verify if ' + user + " already exists")
        result = zapi.user.get(filter={"alias":[user]})
        log.debug(result)
    except Exception as e:
        log.warning(str(e))
        pass
    log.debug("User " + user + " exists?: " + str(len(result) > 0))
    log.debug('JP_ZABBIX : user_exists : END')
    return len(result) > 0

def user_get(user,
             **connection_args):
    log.debug('JP_ZABBIX : user_get : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = []
    try:
        log.debug('Verify if ' + user + " already exists")
        result = zapi.user.get(filter={"alias":[user]})
        log.debug(result)
    except Exception as e:
        log.warning(str(e))
        pass
    log.debug('JP_ZABBIX : user_get : END')
    return result


####################
##      HOST      ##
####################

def host_create(host = None,
                groups = None,
                groupname = None,
                interfaces = None,
                **connection_args):
    log.debug('JP_ZABBIX : host_create : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    if not host_exists(host, **connection_args):
        result = 'Host Already exists !!'
        try:
            if groups == None:
                groups = [{'groupid': hostgroup_get(groupname, **connection_args)[0]['groupid']}]
                log.error(groups)
            log.debug('try adding:')
            log.debug(host)
            log.debug(groups)
            log.debug(interfaces)
            result = zapi.host.create(host=host,
                                      groups=groups,
                                      interfaces=interfaces)
        except Exception as e:
            log.error(str(e))
            pass
        log.debug(result)
    else:
        host_update(host, groups, groupname, interfaces, **connection_args)
    log.debug('JP_ZABBIX : host_create : END')

def host_update(host = None,
                groups = None,
                groupname = None,
                interfaces = None,
                **connection_args):
    log.debug('JP_ZABBIX : host_update : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    if host_exists(host, **connection_args):
        try:
            if groups == None:
                groups = [{'groupid': hostgroup_get(groupname, **connection_args)[0]['groupid']}]
            log.debug('try updating:')
            log.debug(host)
            hostid = host_get(host, **connection_args)[0]['hostid']
            zapi.host.update(hostid=hostid,
                             groups=groups,
                             name=host) #,
#                             interfaces=interfaces)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : host_update : END')

def host_exists(host,
                **connection_args):
    log.debug('JP_ZABBIX : host_exists : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = []
    try:
        log.debug('Verify if ' + host + " already exists")
        result = zapi.host.get(filter={"host":[host]})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug("Host " + host + " exists?: " + str(len(result) > 0))
    log.debug('JP_ZABBIX : host_exists : END')
    return len(result) > 0

def host_get(host,
             **connection_args):
    log.debug('JP_ZABBIX : host_get : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = []
    try:
        result = zapi.host.get(filter={"host":[host]})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : host_get : END')
    return result

def host_enable(host,
                **kwargs):
    log.debug('JP_ZABBIX : host_enable : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    if host_exists(host):
        result = 'Host Already exists !!'
        hostid = host_get(host)[0]['hostid']
        try:
            log.debug('try update status of ' + host + ' to ')
            log.debug(kwargs)
            result = zapi.host.update(hostid=hostid, status=kwargs['status'])
            interfaces = zapi.hostinterface.get()
            for interf in interfaces:
                if interf['hostid'] == hostid:
                    zapi.hostinterface.update(interfaceid=interf['interfaceid'],
                                              ip=kwargs['ip'])
        except Exception as e:
            log.error(str(e))
            pass
        log.debug(result)
    log.debug('JP_ZABBIX : host_enable : END')

def host_delete(**connection_args):
    log.debug('JP_ZABBIX : host_delete : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None

    log.debug('JP_ZABBIX : host_delete : END')
    return

##############
## TEMPLATE ##
##############
def template_get(host,
                 **connection_args):
    log.debug('JP_ZABBIX : template_get : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None
    result = []
    try:
        result = zapi.template.get(filter={"host":[host]})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : template_get : END')
    return result

def template_massadd(templatename,
                     hostnames,
                     **connection_args):
    log.debug('JP_ZABBIX : template_massadd : START')
    zapi = _get_zapi(**connection_args)
    if not zapi:
        return None

    result = []
    templateid = []
    hostsid = []

    templateid.append({
        'templateid': template_get(templatename)[0]['templateid']
    })
    for host in hostnames:
        if host_exists(host):
            hostsid.append({'hostid': host_get(host)[0]['hostid']})
    try:
        if len(hostsid) > 0:
            result = zapi.template.massadd(templates=templateid, hosts=hostsid)
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : template_massadd : END')
#    return result

###########
## MEDIA ##
###########
def mediatype_update(**kwargs):
    log.debug('JP_ZABBIX : media_update : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        result = zapi.mediatype.update(**kwargs)
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : media_update : END')
#    return result


############
## ACTION ##
############
def action_update(**kwargs):
    log.debug('JP_ZABBIX : media_update : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        result = zapi.action.update(**kwargs)
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : media_update : END')
#    return result

##########
## ITEM ##
##########
def item_create(host,
                applicationName=None,
                **kwargs):
    log.debug('JP_ZABBIX : item_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    items = item_get(host, **kwargs)
    if len(hostget) > 0 and len(items) == 0:
        try:
            if applicationName == None:
                zapi.item.create(hostid=hostget[0]['hostid'],
                                 **kwargs)
            else:
                app = application_get(host, applicationName)[0]['applicationid']
                if kwargs['type'] == 0:
                    interfaces = zapi.hostinterface.get()
                    interfaceid = 0
                    for interf in interfaces:
                        if interf['hostid'] == hostget[0]['hostid']:
                            interfaceid = interf['interfaceid']
                    zapi.item.create(hostid=hostget[0]['hostid'],
                                     applications=[app],
                                     interfaceid=interfaceid,
                                     **kwargs)
                else:
                    zapi.item.create(hostid=hostget[0]['hostid'],
                                     applications=[app],
                                     **kwargs)

        except Exception as e:
            log.error(str(e))
            pass
    else:
        try:
            if applicationName == None:
                zapi.item.create(hostid=hostget[0]['hostid'],
                                 **kwargs)
            else:
                app = application_get(host, applicationName)[0]['applicationid']
                if kwargs['type'] == 0:
                    interfaces = zapi.hostinterface.get()
                    interfaceid = 0
                    for interf in interfaces:
                        if interf['hostid'] == hostget[0]['hostid']:
                            interfaceid = interf['interfaceid']
                    zapi.item.update(itemid=items[0]['itemid'],
                                     applications=[app],
                                     interfaceid=interfaceid,
                                     **kwargs)
                else:
                    zapi.item.create(itemid=items[0]['itemid'],
                                     applications=[app],
                                     **kwargs)

        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : item_create : END')
#    return result

def item_get(host,
             **kwargs):
    log.debug('JP_ZABBIX : item_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        hostid = host_get(host)[0]['hostid']
        result = zapi.item.get(hostids=hostid,
                               search={"key_":kwargs['key_']})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : item_get : END')
    return result

###############
## HOSTGROUP ##
###############
def hostgroup_create(hostname,
                     **kwargs):
    log.debug('JP_ZABBIX : hostgroup_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    if len(hostgroup_get(hostname, **kwargs)) == 0:
        try:
           zapi.hostgroup.create({'name': hostname},
                                 **kwargs)
        except Exception as e:
           log.error(str(e))
           pass
    log.debug('JP_ZABBIX : hostgroup_create : END')

def hostgroup_get(hostname,
                  **kwargs):
    log.debug('JP_ZABBIX : hostgroup_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        result = zapi.hostgroup.get(search={"name":[hostname]})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : hostgroup_get : END')
    return result

#################
## APPLICATION ##
#################
def application_create(host,
                       name,
                       **kwargs):
    log.debug('JP_ZABBIX : application_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    result = None
    if len(hostget) > 0 and len(application_get(host, name)) == 0:
        try:
            result = zapi.application.create(hostid=hostget[0]['hostid'],
                                    name=name,
                                    **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : application_create : END')
    return result

def application_get(host,
                    name,
                    **kwargs):
    log.debug('JP_ZABBIX : application_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        hostid = host_get(host)[0]['hostid']
        result = zapi.application.get(hostids=hostid,
                                      search={"name":name})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : application_get : END')
    return result

##############
## HTTPTEST ##
##############
def httptest_create(host,
                    application,
                    name,
                    **kwargs):
    log.debug('JP_ZABBIX : httptest_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    if len(hostget) > 0:
        appid = application_get(host,
                                application)
        if len(appid) == 0:
            appid[0] = application_create(host, application)
        try:
            httptestid = httptest_get(host, name)
            if len(httptestid) == 0:
                zapi.httptest.create(hostid=hostget[0]['hostid'],
                                     name=name,
                                     applicationid=appid[0]['applicationid'],
                                     **kwargs)
            else:
                httptest_update(host=host,
                                application=application,
                                name=name,
                                **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : httptest_create : END')

def httptest_update(host,
                    application,
                    name,
                    **kwargs):
    log.debug('JP_ZABBIX : httptest_update : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    if len(hostget) > 0:
        try:
            appid = application_get(host,
                                    application)
            httptestid = httptest_get(host, name)[0]['httptestid']
            zapi.httptest.update(httptestid=httptestid,
                                 applicationid=appid[0]['applicationid'],
                                 **kwargs)
        except Exception as e:
            log.warning(str(e))
            pass
    log.debug('JP_ZABBIX : httptest_update : END')

def httptest_get(host,
                 name,
                 **kwargs):
    log.debug('JP_ZABBIX : httptest_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        hostid = host_get(host)[0]['hostid']
        result = zapi.httptest.get(hostids=hostid,
                                   search={"name":name})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : httptest_get : END')
    return result

#############
## TRIGGER ##
#############

def trigger_create(host,
                   description,
                   expression,
                   dependencies=None,
                   **kwargs):
    log.debug('JP_ZABBIX : trigger_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    result = None
    if len(hostget) > 0:
        try:
            if len(trigger_get(host, description)) == 0:
                if not dependencies:
                    result = zapi.trigger.create(hostids=hostget[0]['hostid'],
                                                 description=description,
                                                 comments=description,
                                                 expression=expression,
                                                 **kwargs)
                else:
                    dep = []
                    for d in dependencies:
                        dep.append(
                            {'triggerid': trigger_get(host,
                                                      d)[0]['triggerid']}
                        )
                        result = zapi.trigger.create(hostids=hostget[0]['hostid'],
                                                     description=description,
                                                     comments=description,
                                                     expression=expression,
                                                     dependencies=dep,
                                                     **kwargs)
            else:
                trigger_update(host,
                               description,
                               expression,
                               dependencies,
                               **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : trigger_create : END')
    return result

def trigger_update(host,
                   description,
                   expression,
                   dependencies=None,
                   **kwargs):
    log.debug('JP_ZABBIX : trigger_update : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    hostget = host_get(host)
    result = None
    if len(hostget) > 0:
        try:
            triggerid = trigger_get(host, description)[0]['triggerid']
            if not dependencies:
                result = zapi.trigger.update(triggerid=triggerid,
                                             expression=expression,
                                             comments=description,
                                             **kwargs)
            else:
                dep = []
                for d in dependencies:
                    dep.append(
                        {'triggerid': trigger_get(host,
                                                  d)[0]['triggerid']}
                    )
                result = zapi.trigger.update(triggerid=triggerid,
                                             expression=expression,
                                             comments=description,
                                             dependencies=dep,
                                             **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : trigger_update : END')
    return result

def trigger_get(host,
                description=None,
                **kwargs):
    log.debug('JP_ZABBIX : trigger_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        hostid = host_get(host)[0]['hostid']
        result = zapi.trigger.get(hostids=hostid,
                                  search={"description":description})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : trigger_get : END')
    return result

##################
## CONFIGURATON ##
##################
def configuration_import(source=None,
                         format=None,
                         rules=None,
                         **kwargs):
    log.debug('JP_ZABBIX : configuration_import : START')
    zapi = _get_zapi()
    content = None
    if not zapi:
        return None
    try:
        with open(source, 'r') as content_file:
            content = content_file.read()
        zapi.confimport(source=content,
                        format=format,
                        rules=rules)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : configuration_import : END')

###########
## GRAPH ##
###########
def graph_create_nrids(name=None,
                       width=None,
                       height=None,
                       gitems=None,
                       **kwargs):
    log.debug('JP_ZABBIX : graph_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = None
    if graph_get("nrids")[0]['name'] != "nrids":
        try:
            applicationid = zapi.application.get(search={"name":"nrid"})[0]['applicationid']
            itemids = zapi.item.get(applicationids=applicationid)
            r = lambda: random.randint(0,255)
            for item in itemids:
                item['color'] = '%02X%02X%02X' % (r(),r(),r())
            result = zapi.graph.create(name="nrids",
                                       width="900",
                                       height="200",
                                       gitems=itemids,
                                       **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : graph_create : END')
    return result

def graph_create_email_integration(name=None,
                                   width=None,
                                   height=None,
                                   gitems=None,
                                   **kwargs):
    log.debug('JP_ZABBIX : graph_create : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = None
    if graph_get("Email Integration")[0]['name'] != "Email Integration":
        try:
            applicationid = zapi.application.get(search={"name":"Emails Time Stamps"})[0]['applicationid']
            itemids = zapi.item.get(applicationids=applicationid)
            r = lambda: random.randint(0,255)
            for item in itemids:
                item['color'] = '%02X%02X%02X' % (r(),r(),r())
            result = zapi.graph.create(name="Email Integration",
                                       width="900",
                                       height="200",
                                       gitems=itemids,
                                       **kwargs)
        except Exception as e:
            log.error(str(e))
            pass
    log.debug('JP_ZABBIX : graph_create : END')
    return result

def graph_get(name,
              **kwargs):
    log.debug('JP_ZABBIX : graph_get : START')
    zapi = _get_zapi()
    if not zapi:
        return None
    result = []
    try:
        result = zapi.graph.get(search={"name":name})
        log.debug(result)
    except Exception as e:
        log.error(str(e))
        pass
    log.debug('JP_ZABBIX : graph_get : END')
    return result
