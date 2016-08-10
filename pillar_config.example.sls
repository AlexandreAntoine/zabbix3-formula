zabbix3:
  monitoring_configuration:
    hosts:
      host:
        ## info sur l'host -> recherche et ajout avec le sls
        #host:
        #name:
        #etc: ...
        applications:
          - "Emails Time Stamps"
          - "nrid"
        items:
          item:
            name:
            type:
            key:
            delay:
            value_type:
            units:
            description:
            applications:
              - "Emails Time Stamps"
    triggers:
      trigger:
        expression:
        name:
        status:
        priority:
        description:
        type:
        dependencies:
