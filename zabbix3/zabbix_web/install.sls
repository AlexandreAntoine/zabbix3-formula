zabbix-frontend-php:
  pkg.installed


python-pip:
  pkg.installed

pyzabbix:
  pip.installed:
    - require:
      - pkg: python-pip

