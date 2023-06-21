// Define constants
var START_DATE_COL = 13; // Column M
var END_DATE_COL = 14; // Column N
var STATUS_COL = 27; // Column AA
var PERCENTAGE_COL = 28; // Column AB
var MONTH_START_COL = 15; // Column O
var DATA_START_ROW = 7; // Row 7

var BACKGROUND_COLOR = "#ff9900"; // Orange
var DEFAULT_COLOR = "#ffffff"; // White

function onEdit(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getActiveSheet();
  var range = e.range;
  var row = range.getRow();
  var col = range.getColumn();
  var cell = sheet.getRange(row, col);
  var cellValue = cell.getValue();

  // If value of % Complete is changed, then update the value of Status
  if (col == PERCENTAGE_COL && row >= DATA_START_ROW ) {
    var startDate = sheet.getRange(row, START_DATE_COL).getValue();
    var endDate = sheet.getRange(row, END_DATE_COL).getValue();
    var expectedPercentage = calculatePercentage(startDate, endDate);
    var status = calculateStatus(expectedPercentage, cellValue);
    sheet.getRange(row, STATUS_COL).setValue(status);
  }

  // If value of Start Date or End Date is changed
  if (col == START_DATE_COL || col == END_DATE_COL) {
    // Then calculate the status
    var startDate = sheet.getRange(row, START_DATE_COL).getValue();
    var endDate = sheet.getRange(row, END_DATE_COL).getValue();
    var actualPercentage = sheet.getRange(row, PERCENTAGE_COL).getValue();
    var expectedPercentage = calculatePercentage(startDate, endDate);
    var status = calculateStatus(expectedPercentage, actualPercentage);
    sheet.getRange(row, STATUS_COL).setValue(status);


    // Reset color for all months to white, and fill color for the month that is between Start Date and End Date
    var range = sheet.getRange(row, MONTH_START_COL, 1, 12);
    range.setBackground(DEFAULT_COLOR);

    var startMonth = startDate.getMonth();
    var endMonth = endDate.getMonth();
    var startCol = MONTH_START_COL + startMonth;
    var endCol = MONTH_START_COL + endMonth;
    var range = sheet.getRange(row, startCol, 1, endCol - startCol + 1);
    range.setBackground(BACKGROUND_COLOR);
  }
}

// If user delete multiple rows, then reset color for all months to white
function onSelectionChange(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getActiveSheet();
  var range = e.range;
  var row = range.getRow();
  var col = range.getColumn();
  var numRows = range.getNumRows();
  var numCols = range.getNumColumns();

  if (col == 1 && numRows > 1) {
    var range = sheet.getRange(row, MONTH_START_COL, numRows, 12);
    range.setBackground(DEFAULT_COLOR);
  }
}


function calculatePercentage(startDate, endDate) {
  var today = new Date();
  var expectedPercentage = (today - startDate) / (endDate - startDate) * 100;
  return expectedPercentage;
}

function calculateStatus(expectedPercentage, actualPercentage) {
  var status = "";
  if (actualPercentage == 0) {
    status = "Not Started";
  } else if (actualPercentage >= 100) {
    status = "Finished";

  } else if (actualPercentage < expectedPercentage) {
    status = "At Risk";
  } else {
    status = "On Track";
  }
  return status;
}
