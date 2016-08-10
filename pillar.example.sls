{% set minion_ips = salt.saltutil.runner('mine.get', tgt='*', fun='network.ip_addrs',  tgt_type='glob') %}

{% set server_ips = salt.saltutil.runner('mine.get',tgt='roles:zabbix_server', fun='network.ip_addrs',  tgt_type='grain') %}

{% set web_ips = salt.saltutil.runner('mine.get',tgt='roles:zabbix_web', fun='network.ip_addrs',  tgt_type='grain') %}

{% for srv in server_ips %}
{% for web in web_ips %}
{% set zabbix_server_ip = server_ips[srv][0] %}
{% set zabbix_web_ip = web_ips[web][0] %}

zabbix3:
{% if ('zabbix_server' in grains['roles']) and (server_ips | length  == 1) %}
  zabbix_server:
    mysql:
      dbname: zabbix
      dbhost: {{ zabbix_server_ip }}
      dbuser: zabbix
      dbpass: zabbix
      user: root
      grants:
        server_zabbix:
          user: zabbix
          password: zabbix
          grants: all privileges
          host: {{ zabbix_server_ip }}
        server_web:
          user: zabbix
          password: zabbix
          grants: all privileges
          host: {{ zabbix_web_ip }}
{% endif %}
{% if 'zabbix_web' in grains['roles'] and (web_ips | length  == 1) %}
  zabbix_web:
    mysql:
      dbname: zabbix
      dbhost: {{ zabbix_server_ip }}
      dbuser: zabbix
      dbpass: zabbix
    zabbix_server:
      host: {{ zabbix_server_ip }}
{% endif %}

  zabbix_agent:
    zabbix_server:
      host: {{ zabbix_server_ip }}
    UserParameter:
      JP-DB-VISA:
        - "toto"

{% if 'salt' in grains['roles'] %}
  configuration:
    connection_user: admin # MUST BE THE SAME AS admin (see below)
    connection_password: 1234 # idem
    connection_url: "http://{{ zabbix_web_ip }}/zabbix"
    admin:
      alias: admin
      psswd: 1234
    users:
      TOTO:
        psswd: toto
        usrgrpid: 7
        type: 3 # 1 = zabbix user; 2 = zabbix admin; 3 = zabbix super admin
        sendto: blabla@exemple.com
        theme: dark-theme
      Admin2:
        psswd: admin
        usrgrpid: 7
        type: 3 # 1 = zabbix user; 2 = zabbix admin; 3 = zabbix super admin
    dataware_jobs:
      - test
{% endif %}

{% endfor %}
{% endfor %}

mine_functions:
  network.ip_addrs: [eth1]
  get_web_url:
    - mine_function: cmd.shell
    - "grep -riE '^[^#]*server(name|alias)' /etc/apache2/sites-enabled/ | cut -d':' -f2 | awk '{ sub(/.*(S|s)erverName[[:blank:]]*/, \"\"); print }' | sort"

mine_interval: 0.1
