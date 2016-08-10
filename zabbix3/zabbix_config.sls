{% set minion_ips = salt['mine.get']('*', 'network.ip_addrs',  'glob') %}
{% set linux_ips = salt['mine.get']('kernel:Linux', 'network.ip_addrs',  'grain') %}
{% set windows_ips = salt['mine.get']('kernel:Windows', 'network.ip_addrs',  'grain') %}
{% set webserver_url_ips = salt['mine.get']('G@roles:webserver and G@environment:prod', 'get_web_url', 'compound') %}
{% set database_ips_prod = salt['mine.get']('G@roles:database and G@environment:prod', 'network.ip_addrs', 'compound') %}
{% set webserver_ips_prod = salt['mine.get']('G@roles:webserver and G@environment:prod', 'network.ip_addrs', 'compound') %}
{% set webserver_ips = salt['mine.get']('G@roles:webserver', 'network.ip_addrs', 'compound') %}
{% set web_ips = salt['mine.get']('roles:zabbix_web', 'network.ip_addrs',  'grain') %}
{% set server_ips = salt['mine.get']('roles:zabbix_server', 'network.ip_addrs',  'grain') %}

###########################
## update admin password ##
###########################
{% for web in web_ips %}

{% set zabbix_web_ip = web_ips[web][0] %}
{% set admin = salt['pillar.get']('zabbix3:configuration:admin') %}

zabbix3_config_user_update_{{ admin.alias }}:
  module.run:
    - name: jp_zabbix.user_update
    - alias: {{ admin.alias }}
    - psswd: {{ admin.psswd }}
    - type: 3
    - usrgrps:
        - usrgrpid: 7
    - force: True
    - connection_args: # optionnel
        connection_user: "admin"
        connection_password: "zabbix"
        connection_url: "http://{{ zabbix_web_ip }}/zabbix"

{% endfor %}

############################
## IMPORT TEMPLACE CONFIG ##
############################
zabbix3_config_mv_template:
  file.managed:
    - name: /tmp/zapache-template.xml
    - source: salt://zabbix3/files/zapache/zapache-template.xml

zabbix3_config_import_template:
  module.run:
    - name: jp_zabbix.configuration_import
    - source: /tmp/zapache-template.xml
    - format: "xml"
    - rules:
        templates:
          createMissing: True
          updateMissing: True
    - require:
        - file: zabbix3_config_mv_template

## MS SQL 2012 ##
zabbix3_config_mv_template_MS_SQL_2012:
  file.managed:
    - name: /tmp/MS_SQL_2012.xml
    - source: salt://zabbix3/files/MS_SQL_2012.xml

zabbix3_config_import_template_MS_SQL_2012:
  module.run:
    - name: jp_zabbix.configuration_import
    - source: /tmp/MS_SQL_2012.xml
    - format: "xml"
    - rules:
        templates:
          createMissing: True
          updateMissing: True
    - require:
        - file: zabbix3_config_mv_template_MS_SQL_2012

## zbx_IIS8_templates.xml ##
zabbix3_config_mv_template_zbx_IIS8_templates:
  file.managed:
    - name: /tmp/zbx_IIS8_templates.xml
    - source: salt://zabbix3/files/zbx_IIS8_templates.xml

zabbix3_config_import_template_zbx_IIS8_templates:
  module.run:
    - name: jp_zabbix.configuration_import
    - source: /tmp/zbx_IIS8_templates.xml
    - format: "xml"
    - rules:
        templates:
          createMissing: True
          updateMissing: True
    - require:
        - file: zabbix3_config_mv_template_zbx_IIS8_templates

##########################
## add kernel=Liux host ##
##########################
{% for host in linux_ips %}

zabbix3_config_host_create_{{ host }}:
  module.run:
    - name: jp_zabbix.host_create
    - host: {{ host }}
    - groups:
        - groupid: 2
    - interfaces:
        - type: 1
          main: 1
          useip: 1
          ip: {{ minion_ips[host][0] }}
          dns: ""
          port: 10050

{% endfor %}

#############################
## add kernel=Windows host ##
#############################
{% if windows_ips | length > 0 %}
zabbix3_config_hostgroup_create_Windows servers:
  module.run:
    - name: jp_zabbix.hostgroup_create
    - hostname: "Windows servers"

{% for host in windows_ips %}
zabbix3_config_host_create_{{ host }}:
  module.run:
    - name: jp_zabbix.host_create
    - host: {{ host }}
    - groupname: "Windows servers"
    - interfaces:
        - type: 1
          main: 1
          useip: 1
          ip: {{ minion_ips[host][0] }}
          dns: ""
          port: 10050

{% endfor %}
{% endif %}

##########################
## update Zabbix Server ##
##########################
{% for srv in server_ips %}
{% set zabbix_server_ip = server_ips[srv][0] %}

zabbix3_config_host_enable_Zabbix server:
  module.run:
    - name: jp_zabbix.host_enable
    - host: "Zabbix server"  
    - kwargs:
        status: 0
        ip: {{ zabbix_server_ip }}

{% endfor %}

##############
## TEMPLATE ##
##############

## Template ICMP Ping
zabbix_config_template_link_Template ICMP Ping:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template ICMP Ping"
    - hostnames:
{% for id in linux_ips %}
        - {{ id }}
{% endfor %}
{% for id in windows_ips %}
        - {{ id }}
{% endfor %}

## Template OS Linux
zabbix_config_template_link_Template OS Linux:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template OS Linux"
    - hostnames:
{% for id in linux_ips %}
        - {{ id }}
{% endfor %}

## Template OS Windows
{% if windows_ips | length > 0 %}
zabbix_config_template_lin_Template OS Windows:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template OS Windows"
    - hostnames:
{% for id in windows_ips %}
        - {{ id }}
{% endfor %}
{% endif %}

## Template App SSH Service
zabbix_config_template_link_Template App SSH Service:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template App SSH Service"
    - hostnames:
{% for id in linux_ips %}
        - {{ id }}
{% endfor %}

## Template App HTTP Service
{% if webserver_ips_prod | length > 0 %}
zabbix_config_template_link_Template App HTTP Service:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template App HTTP Service"
    - hostnames:
{% for id in webserver_ips_prod %}
        - {{ id }}
{% endfor %}
{% endif %}

## Template App HTTPS Service
{% if webserver_ips_prod | length > 0 %}
zabbix_config_template_link_Template App HTTPS Service:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template App HTTPS Service"
    - hostnames:
{% for id in webserver_ips_prod %}
        - {{ id }}
{% endfor %}
{% endif %}

## Template App Apache Web Server zapache
{% if webserver_ips | length > 0 %}
zabbix_config_template_link_Template App Apache Web Server zapache:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template App Apache Web Server zapache"
    - hostnames:
{% for id in webserver_ips %}
        - {{ id }}
{% endfor %}
{% endif %}

## Template App MySQL
{% if database_ips_prod | length > 0 %}
zabbix_config_template_link_Template App MySQL:
  module.run:
    - name: jp_zabbix.template_massadd
    - templatename: "Template App MySQL"
    - hostnames:
{% for id in database_ips_prod %}
        - {{ id }}
{% endfor %}
{% endif %}

#####################
## add/update user ##
#####################
{% for user, param in salt['pillar.get']('zabbix3:configuration:users', {}).iteritems() %}

zabbix3_config_user_create_{{ user }}:
  module.run:
    - name: jp_zabbix.user_create
    - alias: {{ user }}
    - psswd: {{ param.psswd }}
    - type: {{ param.type }}
    {% if param.theme is defined %}
    - theme: {{ param.theme }}
    {% endif %}
    {% if param.usergroup is defined %}
    - usergroup: {{ param.usergroup }}
    {% endif %}
    - usrgrps:
        - usrgrpid: {{ param.usrgrpid }}

{% if param.sendto is defined %}
zabbix3_config_user_addmedia_{{ user }}:
  module.run:
    - name: jp_zabbix.user_addmedia
    - alias: {{ user }}
    - kwargs:
        medias:
          mediatypeid: "1"
          sendto: "{{ param.sendto }}"
          active: "0"
          severity: "63"
          period: "1-7,00:00-24:00"
    - require:
      - module: zabbix3_config_user_create_{{ user }}
{% endif %}

{% endfor %}


###########
## MEDIA ##
###########
zabbix3_config_media_disable_jabber:
  module.run:
    - name: jp_zabbix.mediatype_update
    - kwargs:
        mediatypeid: 2
        status: 1

zabbix3_config_media_disable_sms:
  module.run:
    - name: jp_zabbix.mediatype_update
    - kwargs:
        mediatypeid: 3
        status: 1


zabbix3_config_media_mail:
  module.run:
    - name: jp_zabbix.mediatype_update
    - kwargs:
        mediatypeid: {{ salt['pillar.get']('zabbix3:configuration:media_mail:mediatypeid') }}
        smtp_port: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_port') }}
        smtp_server: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_server') }}
        smtp_email: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_email') }}
        smtp_helo: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_helo') }}
        smtp_authentication: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_authentication') }}
        smtp_username: {{ salt['pillar.get']('zabbix3:configuration:media_mail:smtp_username') }}
        username: {{ salt['pillar.get']('zabbix3:configuration:media_mail:username') }}
        passwd: {{ salt['pillar.get']('zabbix3:configuration:media_mail:passwd') }}

############
## ACTION ##
############

zabbix3_config_action_enable:
  module.run:
    - name: jp_zabbix.action_update
    - kwargs:
        actionid: 3
        status: 0

#################
## FTP 02 ITEM ##
#################
{% set ftp02_ips = salt['mine.get'](
'JP-FTP02',
'network.ip_addrs',
'glob') %}

zabbix3_config_jp-ftp02_application_create_Cloudinary:
  module.run:
    - name: jp_zabbix.application_create
    - host: 'JP-FTP02'
    - m_name: 'Cloudinary'

{% for srv in ftp02_ips %}

zabbix3_config_item_JP-FTP02_cloudinary.nb_upload_error:
  module.run:
    - name: jp_zabbix.item_create
    - host: {{ srv }}
    - applicationName: Cloudinary
    - kwargs:
        delay: 90
        key_: "cloudinary.nb_upload_error"
        name: "cloudinary.nb_upload_error"
        type: 2 # Zabbix trapper
        value_type: 0 # Decimal
        trapper_hosts: {{ ftp02_ips[srv][0] }}

zabbix3_config_item_JP-FTP02_cloudinary.nb_upload_file:
  module.run:
    - name: jp_zabbix.item_create
    - host: {{ srv }}
    - applicationName: Cloudinary
    - kwargs:
        delay: 90
        key_: "cloudinary.nb_upload_file"
        name: "cloudinary.nb_upload_file"
        type: 2 # Zabbix trapper
        value_type: 0 # Decimal
        trapper_hosts: {{ ftp02_ips[srv][0] }}

{% endfor %}

zabbix3_config_JP-FTP02_trigger_create_cloudinary.nb_upload_error:
  module.run:
    - name: jp_zabbix.trigger_create
    - host: 'JP-FTP02'
    - description: 'cloudinary.nb_upload_error > 0'
    - expression: '{{"{"}}JP-FTP02:cloudinary.nb_upload_error.last(){{"}"}}>0'
    - kwargs:
        priority: 3

###################
## DATAWARE JOBS ##
###################
{% set environments = ['dev', 'test', 'prod'] %}
{% for env in  environments %}

{% set dataware_ips = salt['mine.get'](
'G@environment:'+env+' and G@roles:dataware',
'network.ip_addrs',
'compound') %}

{% for dataware in dataware_ips %}
zabbix3_config_jp-ftp02_application_create_Couldinary:
  module.run:
    - name: jp_zabbix.application_create
    - host: '{{ dataware }}'
    - m_name: 'Dataware'

{% for job in salt['pillar.get']('zabbix3:configuration:dataware_jobs') %}

zabbix3_config_item_dataware_jobs_{{ env }}_{{ job }}:
  module.run:
    - name: jp_zabbix.item_create
    - host: {{ dataware }}
    - applicationName: Dataware
    - kwargs:
        delay: 90
        key_: dataware_{{ env }}_{{ job }}
        name: dataware_{{ env }}_{{ job }}
        type: 2 # Zabbix trapper
        value_type: 4 # text
        trapper_hosts: {{ dataware_ips[dataware][0] }}

zabbix3_config_item_dataware_jobs_{{ env }}_{{ job }}_time:
  module.run:
    - name: jp_zabbix.item_create
    - host: {{ dataware }}
    - applicationName: Dataware
    - kwargs:
        delay: 90
        key_: dataware_{{ env }}_{{ job }}_time
        name: dataware_{{ env }}_{{ job }}_time
        type: 2 # Zabbix trapper
        value_type: 3 # integer
        data_type: 0 # decimal
        trapper_hosts: {{ dataware_ips[dataware][0] }}

{% endfor %}
{% endfor %}

{% endfor  %}

###############################################
## Creat Application, Web scenario & Trigger ##
###############################################
{% for webserver in webserver_url_ips %}
zabbix3_config_{{ webserver }}_application_create_webapplications:
  module.run:
    - name: jp_zabbix.application_create
    - host: {{ webserver }}
    - m_name: WebApplications


{% for url in webserver_url_ips[webserver].split('\n') %}

zabbix3_config_{{ webserver }}_httptest_create_{{ url }}:
  module.run:
    - name: jp_zabbix.httptest_create
    - host: {{ webserver }}
    - application: WebApplications
    - m_name: {{ url }}
    - kwargs:
        steps:
          - name: "INDEX"
            url: "http://{{ url }}"
            status_code: 200
            no: 1

zabbix3_config_{{ webserver }}_trigger_create_{{ url }}:
  module.run:
    - name: jp_zabbix.trigger_create
    - host: {{ webserver }}
    - description: "{{ url }} Status not 200"
    - expression: '({{"{"}}{{ webserver }}:web.test.rspcode[{{ url }},INDEX].min(4m){{"}"}}<>200 and {{"{"}}{{ webserver }}:web.test.rspcode[{{ url }},INDEX].min(4m){{"}"}}<>0) or {{"{"}}{{ webserver }}:web.test.rspcode[{{ url }},INDEX].sum(4m){{"}"}}=0'
    - dependencies:
        - "HTTP service is down on {HOST.NAME}"
    - kwargs:
        priority: 3
{% endfor %}

{% endfor %}


###################################################
## EmailTimeStamp: desk@service-conciergerie.com ##
###################################################

zabbix3_config_jp-bdd1_application_create_Emails Time Stamps:
  module.run:
    - name: jp_zabbix.application_create
    - host: 'jp-bdd1'
    - m_name: 'Emails Time Stamps'

zabbix3_config_jp-bdd1_item_create_desk@service-conciergerie.com:
  module.run:
    - name: jp_zabbix.item_create
    - host: 'jp-bdd1'
    - applicationName: 'Emails Time Stamps'
    - kwargs:
        delay: 60
        key_: 'emailtimestamp.content["desk@service-conciergerie.com"]'
        name: 'desk@service-conciergerie.com'
        type: 0
        value_type: 0
        units: m
        
zabbix3_config_jp-bdd1_trigger_create_desk@service-conciergerie.com:
  module.run:
    - name: jp_zabbix.trigger_create
    - host: 'jp-bdd1'
    - description: 'desk@service-conciergerie.com not updated for 15 min'
    - expression: '{{"{"}}jp-bdd1:emailtimestamp.content["desk@service-conciergerie.com"].last(){{"}"}}>15'
    - kwargs:
        priority: 3

##########
## NRID ##
##########

zabbix3_config_jp-bdd1_application_create_nrid:
  module.run:
    - name: jp_zabbix.application_create
    - host: 'jp-bdd1'
    - m_name: 'nrid'

{% for nrid in salt['pillar.get']('zabbix3:configuration:nrids') %}

zabbix3_config_jp-bdd1_item_create_nrid {{ nrid }}:
  module.run:
    - name: jp_zabbix.item_create
    - host: 'jp-bdd1'
    - applicationName: 'nrid'
    - kwargs:
        delay: 60
        key_: 'monitoring.nrid["{{ nrid }}"]'
        name: 'nrid {{ nrid }}'
        type: 0
        value_type: 0
        
zabbix3_config_jp-bdd1_trigger_create_nrid {{ nrid }}:
  module.run:
    - name: jp_zabbix.trigger_create
    - host: 'jp-bdd1'
    - description: 'nrid {{ nrid }}'
    - expression: '{{"{"}}jp-bdd1:monitoring.nrid["{{ nrid }}"].max(6m){{"}"}}<{{ salt["pillar.get"]("zabbix3:configuration:trigger_nrid", 2000) }}'
    - kwargs:
        priority: 3

{% endfor %}

#############
## GAUMONT ##
#############

## done by configuration/application.sls

###########
## GRAPH ##
###########

zabbix3_config_jp-bdd1_graph_create_nrid:
  module.run:
    - name: jp_zabbix.graph_create_nrids

zabbix3_config_jp-bdd1_graph_create_email_integration:
  module.run:
    - name: jp_zabbix.graph_create_email_integration

include:
  - {{ slspath }}.configuration.application