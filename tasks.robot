*** Settings ***
Documentation     Order robots, save receipts as PDFs and create .zip from results
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Place robot orders, save receipts as PDFs and create .zip
    ${csv_path}=    Confirmation dialog
    Open robot ordering site
    ${orders}=    Get orders    ${csv_path}
    FOR    ${row}    IN    @{orders}
        Close modal
        Place parts    ${row}
        Screenshot preview    ${row}
        Place order
        Create PDF receipt    ${row}
        Embed screenshot to PDF    ${OUTPUT_DIR}${/}PDFs${/}${row}[Order number].pdf    ${OUTPUT_DIR}${/}screenshots${/}${row}[Order number].png
    END
    ZIP PDF files
    [Teardown]    Close Browser

*** Keywords ***
 Confirmation dialog
    ${secret}    Get secret    path
    Add icon    Warning
    Add heading    Use vault for .csv ?
    Add submit buttons    buttons=No,Yes    default=Yes
    ${result}=    Run dialog
    IF    $result.submit == "Yes"
        ${csv}    Set Variable    ${secret}[url]
    ELSE
        ${csv}    Set Variable    https://robotsparebinindustries.com/orders.csv
    END
    [Return]    ${csv}

Open robot ordering site
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${csv}
    Download    ${csv}    orders.csv    overwrite= ${TRUE}
    ${orders}=    Read table from CSV    orders.csv    1
    [Return]    ${orders}

Close modal
    Wait Until Element Is Visible    class:alert-buttons
    Click Button    OK

Place parts
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://div[@id='root']/div/div/div/div/form/div[3]/input    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Screenshot preview
    [Arguments]    ${row}
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}screenshots${/}${row}[Order number].png

Place order
    Wait Until Keyword Succeeds    10 sec    0.1 sec    Place order check

Place order check
    Click Element If Visible    id:order
    Element Should Not Be Visible    css:.alert-danger

Create PDF receipt
    [Arguments]    ${row}
    ${receipt_HTML}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_HTML}    ${OUTPUT_DIR}${/}PDFs${/}${row}[Order number].pdf
    Click Button    id:order-another

Embed screenshot to PDF
    [Arguments]    ${pdf}    ${screenshot}
    Open Pdf    ${pdf}
    ${img}=    Create List    ${screenshot}
    Add Files To Pdf    ${img}    ${pdf}    append=${True}
    Close Pdf

ZIP PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}PDFs${/}    ${OUTPUT_DIR}${/}PDFs.zip
