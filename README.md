# zabbix3-formula
toto


######## Exemple state.sls ########
base:
  'serverZabbix':
    - zabbix3.server_mysql
    - zabbix3.mysql
    - zabbix3.frontend_php
    - zabbix3.agent
