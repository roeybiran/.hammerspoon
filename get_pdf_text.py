#!/usr/bin/python
# coding: utf-8

import sys
from dateutil.relativedelta import relativedelta
from Quartz import PDFDocument
from CoreFoundation import NSURL, NSString

# https://apple.stackexchange.com/questions/2487/how-to-convert-a-pdf-file-into-a-text-file
NSUTF8StringEncoding = 4
filename = sys.argv[1]
inputfile = filename.decode("utf-8")
pdfURL = NSURL.fileURLWithPath_(inputfile)
pdfDoc = PDFDocument.alloc().initWithURL_(pdfURL)
if pdfDoc:
    pdftext = NSString.stringWithString_(pdfDoc.string()).encode("utf8")
    print(pdftext)
