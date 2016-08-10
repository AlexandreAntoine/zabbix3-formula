zabbix_frontend_php_apache2_conf:
  file.managed:
    - name: /etc/apache2/conf-enabled/zabbix.conf
    - source: salt://zabbix3/files/zabbix.conf
    - listen_in:
      - service: zabbix_apache2_service

zabbix_frontend_php_mysql_conf:
  file.managed:
    - name: /etc/zabbix/web/zabbix.conf.php
    - source: salt://zabbix3/files/zabbix.conf.php
    - template: jinja
    - listen_in:
      - service: zabbix_apache2_service