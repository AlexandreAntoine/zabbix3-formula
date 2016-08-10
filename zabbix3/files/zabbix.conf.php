<?php
// Zabbix GUI configuration file.
global $DB;

$DB['TYPE']      = 'MYSQL';
$DB['SERVER']    = '{{ salt['pillar.get']('zabbix3:zabbix_web:mysql:dbhost', 'localhost') }}';
$DB['PORT']      = '0';
$DB['DATABASE']  = '{{ salt['pillar.get']('zabbix3:zabbix_web:mysql:dbname', 'zabbix') }}';
$DB['USER']      = '{{ salt['pillar.get']('zabbix3:zabbix_web:mysql:dbuser', 'zabbix') }}';
$DB['PASSWORD']  = '{{ salt['pillar.get']('zabbix3:zabbix_web:mysql:dbpass', 'zabbix') }}';
// Schema name. Used for IBM DB2 and PostgreSQL.
$DB['SCHEMA']    = '';

$ZBX_SERVER      = '{{ salt['pillar.get']('zabbix3:zabbix_web:zabbix_server:host', 'localhost') }}';
$ZBX_SERVER_PORT = '10051';
$ZBX_SERVER_NAME = 'zabbix server mysql';

$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
?>