*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Excel.Files
Library    RPA.Tables
Library    Collections
Library    RPA.PDF
Library    RPA.FileSystem
Library    RPA.Archive

*** Variables ***
${ordersFile}    ${OUTPUT_dir}${/}orders.csv
${ordersPageURL}    https://robotsparebinindustries.com/#/robot-order
${ordersCSVURL}    https://robotsparebinindustries.com/orders.csv
${robotScreenshotPath}    ${OUTPUT_dir}${/}robot.png
${pdfsFolder}    ${CURDIR}${/}PDFs${/}
${zipPath}    ${OUTPUT_dir}${/}PDF receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Log    Initializing
    Empty Directory    ${pdfsFolder}
    Download CSV
    ${orders}=    Read Orders    ${ordersFile}
    Open the robot order website
    Process All Orders    ${orders}
    Zip all Receipts
    Log    ${orders}

*** Keywords ***
Open the robot order website
    Open Browser    ${ordersPageURL}    browser=chrome
    Click Button    OK


Download CSV
    Download    ${ordersCSVURL}    target_file=${ordersFile}    overwrite=True

Read Orders
    [Arguments]    ${ordersFile}
    ${table}=    Read Table From CSV    ${ordersFile}
    [Return]    ${table}

Process All Orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Process a Single Order    ${order}
    END

Process a Single Order
    [Arguments]    ${order}

    Log    Processing Order ${order}

    ${orderNumber}=    Get From Dictionary    ${order}    Order number
    ${headNumber}=    Get From Dictionary    ${order}    Head
    ${body}=    Get From Dictionary    ${order}    Body
    ${legs}=    Get From Dictionary    ${order}    Legs
    ${address}=    Get From Dictionary    ${order}    Address

    ${partName}=    Number To Part Name    ${headNumber}

    Select From List By Label    id=head    ${partName} head
    Click Element    //label[contains(text(), '${partName} body')]/input
    Input Text    xpath://input[@class='form-control' and @type='number' and @placeholder='Enter the part number for the legs']    ${legs}
    Input Text    id:address    ${address}

    Click Button    id:preview

    Submit Order
    Create PDF Receipt    ${orderNumber}

    Click Button    id:order-another
    Click Button    OK

Zip all Receipts
    Archive Folder With Zip    ${pdfsFolder}    ${zipPath}

Create PDF Receipt
    [Arguments]    ${orderNumber}
    ${receiptHTML}=    Get Element Attribute    id:receipt    innerHTML
    Capture Element Screenshot    id:robot-preview-image    ${robotScreenshotPath}

    ${currPDF}=    SetVariable    ${pdfsFolder}order ${orderNumber}.pdf
    HTML to PDF    ${receiptHTML}    ${currPDF}
    ${files}=    Create List   ${robotScreenshotPath}
    Add Files To Pdf    ${files}    ${currPDF}    1


Submit Order
    ${orderSuccess}=    SetVariable    ${False}
    WHILE    ${orderSuccess} == ${False}
        ${orderSuccess}=    Try submitting
    END

Try submitting
    Click Button    id:order
    ${found}=    Run Keyword And Return Status    Element Should Be Visible    id:order-another
    [Return]    ${found}

Number To Part Name
    [Arguments]    ${orderNumber}
    ${name}=    Run Keyword If
    ...    ${orderNumber} == 1    Set Variable    Roll-a-thor
    ...    ELSE IF    ${orderNumber} == 2    Set Variable    Peanut crusher
    ...    ELSE IF    ${orderNumber} == 3    Set Variable    D.A.V.E
    ...    ELSE IF    ${orderNumber} == 4    Set Variable    Andy Roid
    ...    ELSE IF    ${orderNumber} == 5    Set Variable    Spanner mate
    ...    ELSE IF    ${orderNumber} == 6    Set Variable    Drillbit 2000
    ...    ELSE    Log    Invalid order number: ${orderNumber}
    [Return]    ${name}