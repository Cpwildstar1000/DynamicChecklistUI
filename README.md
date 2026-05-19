# DynamicChecklistUI

# Program Description
This program is to be used to generate notes for whatever is needed

# How to customize
In order to customize this program to work for the checklists that you need it to display you just need to do the following

### Dropdowns
To add custom dropdown options just add what you want displayed in the dropdown as a json file in the templates folder

### Checklists
Modify the json files to contain the checklist options that you want to be displayed. Follow the below format to make sure both the Checkbox and Notes output are correct

{
  "FirstDropdownOption_SecondDropdownOption": {
    "Name": "FirstDropdownOption - SecondDropdownOption",
    "Steps": [
      { "Text": "Text to display as a checkbox", "Output": "Text to outut to the Notes section" },
    ]
  },

If you want the textbox to output nothing to the Notes section then just put "Output": null