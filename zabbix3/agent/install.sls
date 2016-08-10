
{% if grains['kernel'] == 'Linux' %}

{% if 'xenial' in salt['grains.get']('lsb_distrib_codename', {}) %}

#zabbix-pkgrepo:
#  pkgrepo.managed:
#    - name: deb http://repo.zabbix.com/zabbix/3.0/ubuntu {{ grains['oscodename'] }} main
#    - file: /etc/apt/sources.list.d/zabbix.list
#    - keyid: 082AB56BA14FE591
#    - keyserver: keyserver.ubuntu.com

{% else %}

#zabbix-pkgrepo:
#  pkgrepo.managed:
#    - name: deb http://repo.zabbix.com/zabbix/3.0/ubuntu {{ grains['oscodename'] }} main
#    - file: /etc/apt/sources.list.d/zabbix.list
#    - keyid: D13D58E479EA5ED4
#    - keyserver: keyserver.ubuntu.com

{% endif %}

zabbix3-install-agent:
  pkg.installed:
    - name: zabbix-agent

zabbix3-install-sender:
  pkg.installed:
    - name: zabbix-sender
{% else %}
zabbix3-install-agent:
  pkg.installed:
    - name: zabbix-agent
    - version: 3.0.10
{% endif %}
