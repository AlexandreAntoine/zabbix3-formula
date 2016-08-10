zabbix_server_service:
  service.running:
    - name: zabbix-server
    - enable: True
    - relaod: True
    - watch:
      - file: zabbix_server_mysql_conf
    - require:
      - file: zabbix_server_mysql_conf