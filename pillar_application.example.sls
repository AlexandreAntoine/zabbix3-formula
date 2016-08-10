zabbix3:
  configuration:
    applications:
      cinemasgaumont:
        available_tickets:
          delay: 60
          key: custom.mysql.CountNullOrder_idTicket
          type: 0
          value_type: 0
          unit: ticket
          triggers:
            low_tickets:
              description: Under 500 available tickets
              function: last
              comparison: <
              value: 500
              priority: 3
