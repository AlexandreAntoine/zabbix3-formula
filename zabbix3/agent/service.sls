{% if grains['kernel'] == 'Linux' %}
zabbix_agent_service:
  service.running:
    - name: zabbix-agent
    - enable: True
{% else %}
zabbix_agent_service:
  service.running:
    - name: 'Zabbix Agent'
    - enable: True
{% endif %}
