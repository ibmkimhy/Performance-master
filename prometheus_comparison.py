#!/usr/bin/env python3
import pandas as pd
import numpy as np
import logging
import argparse
import textwrap
import sys
import os 
from pathlib import Path
import xlsxwriter

def init():
	global parser
	parser = argparse.ArgumentParser( prog='prometheus_comparison.py', description=textwrap.dedent('''\
	Compares two or more Prometheus summary files.  
	In the case of two provided comparisons, a difference is generated. 
    In the case of three or more provided comparisons, an average of the summaries is generate.
    The output is a spreadsheet, matching the format of the input summaries.
	'''), 
	epilog=textwrap.dedent('''\
	Example: 
	--dirs promTest1 promTest2 --n cp4waiops --loglevel more'''))
	global keyParser
	keyParser = parser.add_argument_group('KEY arguments')
	global requiredParser
	requiredParser = parser.add_argument_group('REQUIRED arguments')
	setupParser()
	global arg 
	arg = parser.parse_args()
	setupLogging()
	global itemDict 
	itemDict = {}
	global columnDict 
	columnDict = {}
	global sheetDict
	sheetDict = {}
	global summary_files
	summary_files = []
	global excelFiles
	excelFiles = {}
def setupParser():
	requiredParser.add_argument(
		"--dirs", 
		nargs='+',
		help=("List of derectories with Prometheus exported summary(ies)")
	)
	requiredParser.add_argument(
		"--n",
		"--namespace",
		dest='namespace',
		help=("Namespace to compare summary data for"),
		required=True
	)
	keyParser.add_argument(
		"--loglevel", 
		default="info",
		help=("Logging level: critical, error, warn, warning, info, prog, more, debug, verbose.  Default is info.")
	)
	keyParser.add_argument(
		"--outputDir", 
		default="",
		help=("Directory to ouput the results to")
	)
def setupLogging():
	logging.PROG = 19
	logging.addLevelName(logging.PROG, "PROG")
	logging.Logger.prog = lambda inst, msg, *args, **kwargs: inst.log(logging.PROG, msg, *args, **kwargs)
	logging.prog = lambda msg, *args, **kwargs: logging.log(logging.PROG, msg, *args, **kwargs)
	
	logging.MORE = 15
	logging.addLevelName(logging.MORE, "MORE")
	logging.Logger.more = lambda inst, msg, *args, **kwargs: inst.log(logging.MORE, msg, *args, **kwargs)
	logging.more = lambda msg, *args, **kwargs: logging.log(logging.MORE, msg, *args, **kwargs)
	
	logging.VERBOSE = 5
	logging.addLevelName(logging.VERBOSE, "VERBOSE")
	logging.Logger.verbose = lambda inst, msg, *args, **kwargs: inst.log(logging.VERBOSE, msg, *args, **kwargs)
	logging.verbose = lambda msg, *args, **kwargs: logging.log(logging.VERBOSE, msg, *args, **kwargs)
	
	levels = {
		'critical': logging.CRITICAL,
		'error': logging.ERROR,
		'warn': logging.WARNING,
		'warning': logging.WARNING,
		'info': logging.INFO,
		'prog': logging.PROG,
		'more': logging.MORE,
		'debug': logging.DEBUG,
		'verbose': logging.VERBOSE
	}
	level = levels.get(arg.loglevel.lower())
	logging.basicConfig(stream=sys.stdout, level=level, format='%(asctime)s %(levelname)-8s %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
	logging.info("logging level: " + str(level))
def searchDirs():
	for dir in arg.dirs: 
		if not dir.endswith("/"):
			dir = dir + "/"
		logging.prog("searchDirs  Looking in dir " + dir )
		files = os.listdir(dir)
		for file in files:
			if arg.namespace in file and ".summary." in file and not file.startswith("~"):
				logging.more("searchDirs   * " + str(file))
				summary_files.append(dir + file)
			else:
				logging.more("searchDirs     " + str(file))
	x=0
	logging.prog("searchDirs  Found " + str(len(summary_files)) + " matching files")
	for file in summary_files:
		x+=1
		logging.prog("searchDirs  Summary file " + str(x) + " " + str(file))
		excelFiles[file] = {}
		excelFiles[file]["ExcelFile"] = pd.ExcelFile(file)
		loadSheets(file)
def removeHeaderIndents(column):
	return column.replace('\r','').replace('\n', ' ')
def loadSheets(file):
	sheets = excelFiles[file]["ExcelFile"].sheet_names
	excelFiles[file]["sheets"] = {}
	for sheet in sheets:
		logging.more("loadSheets   sheet: " + sheet)
		excelFiles[file]["sheets"][sheet] = pd.read_excel(excelFiles[file]["ExcelFile"], sheet)
		sheetDict[sheet] = {}
def getItems(sheet, df):
	items = df.loc[:,'Item']
	for item in items:
		itemDict[sheet][item] = {}
def getColumns(sheet, df):
	columns = df.columns.values.tolist()
	x=0
	for column in columns:
		columnDict[sheet][column] = ""
		x+=1
def buildDefaultSheetContents():	
	for sheet in sheetDict:
		itemDict[sheet] = {}
		columnDict[sheet] = {}
		logging.prog("buildDefaultSheetContents  Looking at sheet: " + sheet)
		for file in excelFiles:
			if sheet in excelFiles[file]["sheets"]:
				logging.more("buildDefaultSheetContents   " + file + " has " + sheet)
				getItems(sheet, excelFiles[file]["sheets"][sheet])
				getColumns(sheet, excelFiles[file]["sheets"][sheet])
			else:
				logging.warning("buildDefaultSheetContents  " + file + " does not have " + sheet + ", skipping...")
		if logging.DEBUG >= logging.root.level:
			for item in itemDict[sheet]:
				logging.debug("buildDefaultSheetContents  " + sheet + " item: " + item)
			for column in columnDict[sheet]:
				logging.debug("buildDefaultSheetContents  " + sheet + " column: " + removeHeaderIndents(column))
def iterateOverSheets():
	for sheet in sheetDict:
		for file in excelFiles:
			if sheet in excelFiles[file]["sheets"]:
				logging.prog("iterateOverSheets  File: " + file + " Sheet: " + sheet)
				df = excelFiles[file]["sheets"][sheet]
				itemsInSheet = df['Item'].tolist()
				columnsInSheet = df.columns.values.tolist()
				row=-1
				for item in itemDict[sheet]: 
					if item in itemsInSheet:
						row+=1
						logging.more("iterateOverSheets   File: " + file + " Sheet: " + sheet + " item: " + item)
						for column in columnDict[sheet]:
							if column in columnsInSheet:
								value = df.iloc[row][column]
								if column not in itemDict[sheet][item]:
									itemDict[sheet][item][column] = []
								itemDict[sheet][item][column].append(value)
								logging.verbose("value " + str(itemDict[sheet][item][column]))
							else:
								itemDict[sheet][item][column] = []
def setupXLSX():
	xlsxFileName = "test.xlsx"
	
	if arg.outputDir:
		logging.prog("setupXLSX  Creating directory: " + arg.outputDir)
		Path(arg.outputDir).mkdir(parents=True, exist_ok=True)
		xlsxFileNameFull = arg.outputDir + "/" + xlsxFileName
	else:
		xlsxFileNameFull = xlsxFileName
		
	if os.path.exists(xlsxFileName):
		logging.prog("Removing xlsx file: " + xlsxFileName)
		os.remove(xlsxFileName)
	workbook = xlsxwriter.Workbook(xlsxFileNameFull, {'strings_to_numbers': True})
	formats = {}
	formats["textWrap"] = workbook.add_format({'text_wrap': True})
	formats["decimal"] = workbook.add_format({'num_format': '#,##0.000'})
	formats["integer"] = workbook.add_format({'num_format': '#,##0'})
	formats["percent"] = workbook.add_format({'num_format': '0.00%'})
	return workbook, formats
def printAllValues(fileCount):
	workbook, formats = setupXLSX()
	for sheet in sheetDict:
		worksheet = workbook.add_worksheet(sheet)
		worksheet.freeze_panes(1,1)
		worksheet.set_column('A:A', 50)
		columnNum=0
		for header in columnDict[sheet]:
			worksheet.write(0, columnNum, header + "\n[Avg]", formats["textWrap"])
			if fileCount == 2:
				worksheet.write(0, columnNum, header + "\n[Diff]", formats["textWrap"])
				columnNum+=1
			columnNum+=1
		rowNum=0
		for item in itemDict[sheet]:
			rowNum+=1
			worksheet.write(rowNum, 0, item)
			columnNum=0
			for header in itemDict[sheet][item]:
				if columnNum > 0:
					values = itemDict[sheet][item][header]
					logging.info("test " + header)
					total = sum(values)
					count = len(values)
					if count > 0 :
						avg = total / count
					else:
						avg = 0	
					diff = ""
					if fileCount == 2:
						if count == 2:
							diff = float(values[1]) - float(values[0])
						
					formatName="decimal"
					if "(%)" in header:
						formatName="percent"						
					elif "(Mi)" in header or "(int)" in header:
						formatName="integer"
					format = formats[formatName]
					if logging.DEBUG >= logging.root.level:
						logging.debug("printValues  sheet " + sheet + " item " + item + " header " + removeHeaderIndents(header) + "  storing \"" + str(values) + "\" to " + str(rowNum) + " " + str(columnNum) + " format " + formatName)
						for value in values:
							logging.debug("value " + value)
							

					worksheet.write(rowNum, columnNum, avg, format)
					if fileCount == 2:
						worksheet.write(rowNum, columnNum, diff, format)
						columnNum+=1					
				columnNum+=1
	workbook.close()
	
def main():
	init()
	searchDirs()
	if len(summary_files) < 2 : 
		logging.error("main  Only found " + str(len(summary_files)) + " file. 2 or more are required")
		exit()
		
	buildDefaultSheetContents()
	iterateOverSheets()
	printAllValues(len(summary_files))

main()
exit()
