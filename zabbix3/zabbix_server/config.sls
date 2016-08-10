zabbix_server_mysql_conf:
  file.managed:
    - name: /etc/zabbix/zabbix_server.conf
    - source: salt://zabbix3/files/zabbix_server.conf
    - template: jinja
    - listen_in:
      - service: zabbix_server_service
    - require:
      - pkg: zabbix3-install-server-mysql
