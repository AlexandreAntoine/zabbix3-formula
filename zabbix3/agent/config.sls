zabbix_agent_conf:
  file.managed:
{% if grains['kernel'] == 'Linux' %}
    - name: /etc/zabbix/zabbix_agentd.conf
    - source: salt://zabbix3/files/zabbix_agentd.conf
{% elif grains['cpuarch'] == 'AMD64' %}
    - name: 'C:\Program Files\Zabbix Agent\zabbix_agentd.conf'
    - source: salt://zabbix3/files/zabbix_agentd_win.conf
{% else %}
    - name: 'C:\Program Files (x86)\Zabbix Agent\zabbix_agentd.conf'
    - source: salt://zabbix3/files/zabbix_agentd_win.conf
{% endif %}
    - template: jinja
    - listen_in:
      - service: zabbix_agent_service
{% if grains['kernel'] == 'Linux' %}
    - require:
        - pkg: zabbix3-install-agent
{% endif %}

{% if 'webserver' in salt['grains.get']('roles') %}

zabbix_agent_install_zapache:
  file.managed:
    - name: /var/lib/zabbixsrv/externalscripts/zapache
    - source: salt://zabbix3/files/zapache/zapache
    - makedirs: True
    - mode: 0755

zabbix_agent_conf_userparameter_zapache:
  file.managed:
    - name: /etc/zabbix/zabbix_agentd.d/userparameter_zapache.conf
    - source: salt://zabbix3/files/zapache/userparameter_zapache.conf.sample
    - mode: 0644
    - listen_in:
      - service: zabbix_agent_service
    - require:
        - pkg: zabbix3-install-agent

{% endif %}