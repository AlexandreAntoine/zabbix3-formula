{% set zabbix3 = salt['pillar.get']('zabbix3') %}

zabbix3_database_present:
  mysql_database.present:
    - name: zabbix
    - connection_user: {{ zabbix3.zabbix_server.mysql.user }}
{% if zabbix3.zabbix_server.mysql.pass is defined %}
    - connection_pass: {{ zabbix3.zabbix_server.mysql.pass }}
{% endif %}
    - require:
      - pkg: zabbix3-install-server-mysql

{% for srv, config in salt['pillar.get']('zabbix3:zabbix_server:mysql:grants', {}).iteritems() %}
zabbix3_mysql_user_{{ srv }}:
  mysql_user.present:
    - name: {{ config.user }}
    - host: {{ config.host }}
    - password: {{ config.password }}
    - connection_user: {{ zabbix3.zabbix_server.mysql.user }}
{% if zabbix3.zabbix_server.mysql.pass is defined %}
    - connection_pass: {{ zabbix3.zabbix_server.mysql.pass }}
{% endif %}
    - require:
      - pkg: zabbix3-install-server-mysql


zabbix_mysql_grants_{{ srv }}:
  mysql_grants.present:
    - grant: {{ config.grants }}
    - database: 'zabbix.*'
    - user: {{ config.user }}
    - host: {{ config.host }}
    - connection_user: {{ zabbix3.zabbix_server.mysql.user }}
{% if zabbix3.zabbix_server.mysql.pass is defined %}
    - connection_pass: {{ zabbix3.zabbix_server.mysql.pass }}
{% endif %}
    - require:
      - mysql_user: zabbix3_mysql_user_{{ srv }}

{% endfor %}

zabbix3_mysql_filedb:
  file.managed:
    - name: /tmp/zabbix.sql.gz
    - source: {{ salt['pillar.get']('zabbix3:zabbix_server:mysql:database_path', 'salt://zabbix3/files/create.sql.gz') }}
    - replace: True
    - onchanges:
      - mysql_database: zabbix3_database_present

zabbix3_create_database:
  cmd.run:
    - name: |
        zcat /tmp/zabbix.sql.gz | mysql -u{{ zabbix3.zabbix_server.mysql.user }} {% if zabbix3.zabbix_server.mysql.pass is defined %}-p{{ zabbix3.zabbix_server.mysql.pass }}{% endif %} zabbix
        rm /tmp/zabbix.sql.gz
    - onchanges:
      - file: zabbix3_mysql_filedb

zabbix3_mysql_conf:
  file.replace:
    - name: /etc/mysql/my.cnf
    - pattern: "bind-address.*"
    - repl: "bind-address = 0.0.0.0"
    - listen_in:
      - service: zabbix_mysql_service
    - require:
      - cmd: zabbix3_create_database

zabbix_mysql_service:
  service.running:
    - name: mysql
    - enable: True
    - watch:
      - file: zabbix3_mysql_conf
