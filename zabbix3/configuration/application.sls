{% for application, app_param in salt['pillar.get']('zabbix3:configuration:applications', {}).iteritems() %}

{% if app_param.role is defined %}
# Get hosts from roles (items.roles)
{% else %}
{% set hosts = salt['mine.get']('applications:' + application, 'network.ip_addrs',  'grain') %}
{% endif %}

{% for host,ip in hosts.iteritems() %}

zabbix3_config_{{ host }}_application_create_{{ application }}:
  module.run:
    - name: jp_zabbix.application_create
    - host: '{{ host }}'
    - m_name: '{{ application }}'

{% for item, param in app_param.items.iteritems() %}

zabbix3_config_{{ host }}_item_create_{{ item }}:
  module.run:
    - name: jp_zabbix.item_create
    - host: '{{ host }}'
    - applicationName: '{{ application }}'
    - kwargs:
        delay: {{ param.delay }}
        key_: '{{ param.key }}'
        name: '{{ item }}'
        type: {{ param.type }}
        value_type: {{ param.value_type }}
        units: {{ param.unit }}

{% for trigger,trig_param in param.triggers.iteritems() %}

zabbix3_config_{{ host }}_trigger_create_{{ item }}:
  module.run:
    - name: jp_zabbix.trigger_create
    - host: '{{ host }}'
    - description: '{{ trig_param.description }}'
    - expression: '{{"{"}}{{ host }}:{{ param.key }}.{{ trig_param.function }}(){{"}"}}{{ trig_param.comparison }}{{ trig_param.value }}'
    - kwargs:
        priority: {{ trig_param.priority }}

{% endfor %}
{% endfor %}
{% endfor %}
{% endfor %}
