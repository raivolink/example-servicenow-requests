*** Settings ***
Documentation       Example robot for using Servicenow API calls

Library             RPA.HTTP
Library             RPA.JSON
Library             RPA.Tables
Library             OperatingSystem
Library             Collections

Suite Setup         Create SNow Connection
Suite Teardown      Delete All Sessions


*** Variables ***
${BASE_URL}     https://dev84941.service-now.com


*** Tasks ***
Servicenow Requests
    Log To Console    \n
    ${table_of_records}=    Get Records As Table    records=2
    Write table to CSV    ${table_of_records}    ${OUTPUT_DIR}${/}sn.csv
    #Create New Incident From Data
    Create Table Record And Update It
    Get Incident Data With Ticket number


*** Keywords ***
Create SNow Connection
    [Documentation]    apitest    K11sum11su!
    ${auth}=    Create List    apitest    K11sum11su!
    Create Session    snow
    ...    ${BASE_URL}
    ...    auth=${auth}
    ...    disable_warnings=True

Get Records From Table
    [Arguments]    ${table_name}=incident    &{params}
    IF    not ${params}
        Log    ${\n}No input    console=true
        &{params}=    Create Dictionary
        ...    sysparm_limit=1
    END
    ${response}=    GET On Session
    ...    snow
    ...    /api/now/table/${table_name}
    ...    params=${params}
    RETURN    ${response.json()}

Get Records As Table
    [Arguments]    ${table_name}=incident    ${records}=10
    &{params}=    Create Dictionary
    ...    sysparm_limit=${records}
    ${response_json}=    Get Records From Table    params=${params}
    Save JSON to file    ${response_json}    jason.json
    ${records_as_table}=    Create Table    ${response_json}[result]
    RETURN    ${records_as_table}

Create Table Record
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
    [Arguments]    ${table_name}    ${sys_id}    ${record_bodydata}    ${params}=${EMPTY}
    ${resp}=    PUT On Session
    ...    snow
    ...    url=${BASE_URL}/api/now/table/${table_name}/${sys_id}
    ...    json=${record_bodydata}
    ...    expected_status=200

Create New Incident From Data
    [Documentation]    Example creates incident and attaches
    ...    pdf file to request
    &{ticket_bodydata}=    Create Dictionary
    ...    caller_id=6c35b72a4702211062ede357536d439d
    ...    short_description=Test from API request
    ${ticket_sys_id}    ${ticket_number}=    Create Table Record    incident    request_body=&{ticket_bodydata}
    Attach Pdf File To Table Record    ${ticket_sys_id}
    ...    testpdf.pdf
    ...    devdata${/}TestPDFfile.pdf

Attach Pdf File To Table Record
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
    &{ticket_bodydata}=    Create Dictionary
    ...    caller_id=6c35b72a4702211062ede357536d439d
    ...    short_description=Request creation and update
    ${ticket_sys_id}    ${ticket_number}=    Create Table Record    incident    request_body=&{ticket_bodydata}
    ${json_body}=    Load JSON from file    devdata${/}update_request.json
    &{json_body}=    Convert To Dictionary    ${json_body}
    Update Table Record    incident
    ...    ${ticket_sys_id}
    ...    ${json_body}

Get Incident Data With Ticket number
    &{params}=    Create Dictionary
    ...    sysparm_query=numberSTARTSWITHINC0010014
    ${ticket__data}=    Get Records From Table    incident    &{params}
    Log    ${ticket__data}    console=${True}
