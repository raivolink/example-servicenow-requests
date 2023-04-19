# ServiceNow Requests With Robocorp

This robot illustrates how you could make request against ServiceNow instance using only the robot framework.

**NOTE: This robot expects that there is a user set up with access to ServiceNow REST API request.  
Credentials are saved in Control Room Vault**

⚠️ Although API allows using of requests ignoring mandatory fields, all POST requests should respect those.

Main tasks has few example keword usages:

```robotframework
*** Tasks ***
Servicenow Requests
    ${table_of_records}=    Get Records As Table    incident    records=2
    Write table to CSV    ${table_of_records}    ${OUTPUT_DIR}${/}sn.csv
    Create New Incident And Attach File
    Create Table Record And Update It
    ${ticket__data}=    Get Incident Data With Ticket number    INC0010016
```

## Learning materials

- [Robocorp Developer Training Courses](https://robocorp.com/docs/courses)
- [Documentation links on Robot Framework](https://robocorp.com/docs/languages-and-frameworks/robot-framework)
- [ServiceNow documentation](https://docs.servicenow.com/bundle/rome-application-development/page/integrate/inbound-rest/concept/use-REST-API-Explorer.html)
