#!/usr/bin/python
# coding: utf-8

import sys
import os
from dateutil.relativedelta import relativedelta
from Quartz import PDFDocument
from CoreFoundation import NSURL, NSString
from datetime import datetime

NSUTF8StringEncoding = 4


names = {
    "bezeqint": "בזק בינלאומי",
    "payme": "פאיימי",
    "avrech": "אברך-אלון",
    "bezeq": "בזק החברה הישראלית לתקשורת",
    "apple music": "Apple Music",
    "apple icloud": "iCloud:",
}

now = datetime.now()
one_month_ago = now + relativedelta(months=-1)
month = one_month_ago.month
year = one_month_ago.year
filename = sys.argv[1]

# https://apple.stackexchange.com/questions/2487/how-to-convert-a-pdf-file-into-a-text-file
inputfile = filename.decode("utf-8")
pdfURL = NSURL.fileURLWithPath_(inputfile)
pdfDoc = PDFDocument.alloc().initWithURL_(pdfURL)
if pdfDoc:
    pdftext = NSString.stringWithString_(pdfDoc.string()).encode("utf8")
    for name in names:
        if names[name] in pdftext:
            outputfile = "{}/Downloads/{} {}-{}.pdf".format(
                os.getenv("HOME"), name, year, month
            )
            os.rename(
                inputfile,
                outputfile,
            )
            break
