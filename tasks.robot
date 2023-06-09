*** Settings ***
Documentation       Example robot for using Servicenow API calls

Library             RPA.HTTP
Library             RPA.JSON
Library             RPA.Tables
Library             OperatingSystem
Library             Collections
Library             RPA.Robocorp.Vault

Suite Setup         Create SNow Connection
Suite Teardown      Delete All Sessions


*** Variables ***
${BASE_URL}             https://dev172181.service-now.com
${CALLER_ID}            005d500b536073005e0addeeff7b12f4    #change to existing user
${SHORT_DESCRIPTION}    Request made by API example


*** Tasks ***
Servicenow Requests
    ${table_of_records}=    Get Records As Table    incident    records=2
    Write table to CSV    ${table_of_records}    ${OUTPUT_DIR}${/}sn.csv
    Create New Incident And Attach File
    Create Table Record And Update It
    ${ticket__data}=    Get Incident Data With Ticket number    INC0010016


*** Keywords ***
Create SNow Connection
    [Documentation]    Creates connection to Servicenow instance
    ...    Requirers username and password. User has to have api access

    ${SNOW_cred}=    Get Secret    SNow
    Set Log Level    NONE
    ${auth}=    Create List    ${SNOW_cred}[username]    ${SNOW_cred}[password]
    Set Log Level    INFO
    Create Session    snow
    ...    ${BASE_URL}
    ...    auth=${auth}
    ...    disable_warnings=True

Get Records From Table
    [Arguments]    ${table_name}=incident    ${params}=${EMPTY}

    IF    not ${params}
        Log    ${\n}No input    console=true
        &{params}=    Create Dictionary
        ...    sysparm_limit=1
    END

    ${response}=    GET On Session
    ...    snow
    ...    /api/now/table/${table_name}
    ...    params=${params}
    ...    expected_status=200

    RETURN    ${response.json()}

Get Records As Table
    [Arguments]    ${table_name}=incident    ${records}=10

    &{params}=    Create Dictionary
    ...    sysparm_display_value=true
    ...    sysparm_exclude_reference_link=true
    ...    sysparm_limit=${records}

    ${response_json}=    Get Records From Table    ${table_name}    params=&{params}
    ${records_as_table}=    Create Table    ${response_json}[result]

    RETURN    ${records_as_table}

Create Table Record
    [Documentation]    Creates record to given table, returns
    ...    created sys_id and ticket number
    ...    Keyword fails if api does not return sys_id
    [Arguments]    ${table_name}    ${request_body}    ${params}=${EMPTY}

    ${response}=    POST On Session
    ...    snow
    ...    /api/now/table/${table_name}
    ...    params=${params}
    ...    json=${request_body}
    ...    params=${params}

    ${ticket_sys_id}=    Get value from JSON    ${response.json()}    $.result[*].sys_id
    Should Not Be Equal    '${ticket_sys_id}'    'None'    msg=No sys_id for created ticket
    ${ticket_number}=    Get value from JSON    ${response.json()}    $.result[*].number

    RETURN    ${ticket_sys_id}    ${ticket_number}

Update Table Record
    [Documentation]    Updates reocrd in table
    ...    Expects updated fields as json data
    [Arguments]    ${table_name}    ${sys_id}    ${record_bodydata}    ${params}=${EMPTY}

    ${resp}=    PUT On Session
    ...    snow
    ...    url=${BASE_URL}/api/now/table/${table_name}/${sys_id}
    ...    json=${record_bodydata}
    ...    params=${params}
    ...    expected_status=200

Create New Incident And Attach File
    [Documentation]    Example creates incident and attaches
    ...    pdf file to request
    ...
    &{ticket_bodydata}=    Create Dictionary
    ...    caller_id=${CALLER_ID}    #change to existing user
    ...    short_description=${SHORT_DESCRIPTION}

    ${ticket_sys_id}    ${ticket_number}=    Create Table Record    incident    request_body=&{ticket_bodydata}
    Log    Created ticket ${ticket_number}    console=${True}

    Attach Pdf File To Table Record    ${ticket_sys_id}
    ...    testpdf.pdf
    ...    devdata${/}TestPDFfile.pdf

Attach Pdf File To Table Record
    [Documentation]    Attaches pdf file to an existing ticket
    ...    $ticket_sys_id is record to which file will be attached
    ...    $attachment_name is name that will be shown from ticket
    [Arguments]    ${ticket_sys_id}    ${attachment_name}    ${file_path}    ${target_table}=incident

    &{headers}=    Create Dictionary    Content-Type=application/pdf
    ${data}=    Get Binary File    ${file_path}
    &{files}=    Create Dictionary    file=${data}
    &{params}=    Create Dictionary
    ...    table_name=${target_table}
    ...    table_sys_id=${ticket_sys_id}
    ...    file_name=${attachment_name}

    ${resp}=    POST On Session
    ...    snow
    ...    url=/api/now/attachment/file    params=${params}
    ...    data=${data}
    ...    headers=&{headers}
    ...    expected_status=201

Create Table Record And Update It
    [Documentation]    Creates request and then uses data from
    ...    json template to update the ticket.
    ...
    &{ticket_bodydata}=    Create Dictionary
    ...    caller_id=${CALLER_ID}    #change to existing user
    ...    short_description=${SHORT_DESCRIPTION}
    ${ticket_sys_id}    ${ticket_number}=    Create Table Record    incident    request_body=&{ticket_bodydata}

    ${json_body}=    Load JSON from file    devdata${/}update_request.json
    &{json_body}=    Convert To Dictionary    ${json_body}

    Update Table Record    incident
    ...    ${ticket_sys_id}
    ...    ${json_body}

Get Incident Data With Ticket number
    [Documentation]    Creates request and then uses data from
    ...    json template to update the ticket.
    ...
    [Arguments]    ${ticket_number}

    &{params}=    Create Dictionary
    ...    sysparm_query=numberSTARTSWITH${ticket_number}
    ${ticket_data}=    Get Records From Table    incident    ${params}

    RETURN    ${ticket_data}
