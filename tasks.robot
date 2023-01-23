*** Settings ***
Documentation       Order new robots from RobotSpareBin Industries's website.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archives of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Robocorp.Vault
Library             RPA.Tables
Library             OperatingSystem
Library             RPA.Dialogs
Library             RPA.PDF
Library             RPA.FileSystem
Library             Dialogs
Library             RPA.Archive


*** Variables ***
${zip_dir}              ${OUTPUT_DIR}
${images_directory}     ${OUTPUT_DIR}/PDFs


*** Tasks ***
Order new robots from RobotSpareBin Industries's website.
    Open the robot order website
    Get CSVFile URL and download file
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Close modal
        Fill the form    ${order}
        ${pdf_path}=    Save the receipt as PDF
        ${robot_image}=    Get screenshot of the robot
        Embed robot image to PDF file    ${pdf_path}    ${robot_image}
        Click to order another robot
    END
    Log out and close browser
    Create zip file
    Delete images


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get CSVFile URL and download file
    ${csv_url}=    Get Secret    CSVFilePath
    Download    ${csv_url}[value]    overwrite=True

Get orders
    ${orders}=    Read table from CSV    path=orders.csv    header=True
    RETURN    ${orders}

Close modal
    Wait Until Page Contains Element    class:btn-dark
    Click Button    class:btn-dark

Submit order
    Click Button    id:order
    Page Should Contain Element    id:receipt

Fill the form
    [Arguments]    ${order}
    Sleep    3s
    Select From List By Index    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Wait Until Keyword Succeeds    5x    8s    Submit order

Save the receipt as PDF
    ${order_number}=    Get Text    //*[@id="receipt"]/p[1]
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}/PDFs/${order_number}.pdf
    ${pdf_path}=    Absolute Path    ${OUTPUT_DIR}/PDFs/${order_number}.pdf
    RETURN    ${pdf_path}

Get screenshot of the robot
    ${order_number}=    Get Text    //*[@id="receipt"]/p[1]
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}/PDFs/image_${order_number}.png
    ${robot_image}=    Absolute Path    ${OUTPUT_DIR}/PDFs/image_${order_number}.png
    RETURN    ${robot_image}

Embed robot image to PDF file
    [Arguments]    ${pdf_path}    ${robot_image}
    Open Pdf    ${pdf_path}
    @{files_to_combine}=    Create List
    ...    ${pdf_path}
    ...    ${robot_image}:align=center
    Add Files To Pdf    ${files_to_combine}    ${pdf_path}
    Close Pdf    ${pdf_path}

Click to order another robot
    Click Button    id:order-another

Log out and close browser
    Close Browser

Create zip file
    ${zip_name}=    Get Value From User
    ...    What name for the zip file would you like to give? DON'T FORGET TO INCLUDE '.zip'
    Archive Folder With Zip    ${images_directory}    ${zip_dir}/${zip_name}

Delete images
    Empty Directory    ${images_directory}
