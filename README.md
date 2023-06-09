# QR-Rechnung
Postfinance QR Invoicing - Shell Script Based on CURL &amp; Python

## Overview
Simple wrapper-script which enables every Swiss company or individual - generating valid QR-invoice using public Postfinance API.

The process of generating QR-invoice via Swiss Postfinance service has to follow one of the different paths described below, in order to end up with a valid payment request (replacing old pink/yellow BVR). Here the tracked cases:
 - [x] payment to CREDITOR with an AMOUNT and a specific DEBITOR
 - [x] payment to CREDITOR with an AMOUNT but no specific DEBITOR information
 - [x] payment to CREDITOR without any precise AMOUNT, addressed to specific DEBITOR
 - [x] payment to CREDITOR without any precise AMOUNT and without specific DEBITOR information

Depending on the above needs - configurable via script option - all of the basic input variables to be used in API/POST will be automatically adjusted. 

Few examples IRL:
1. a charity organization wants to send open "donation demand" to list of known individuals
2. a solidarity cause for food-collection want to distribute open letter and flyers - along with the QR code - without previous knowledge of donated amount of nor the donor's coordinates (i.e. public events)
3. your company wants to regularly output precise invoices to existing customers - integrating with Filemaker, SAP, Success Factor or other CRM applications.

Check all of the Creditor and Debitor mandatory parameters, along with few optional/dynamic ones (i.e. the amount of the invoice itself).

## Purpose
*The script - opensource - aims to cover all of cases previously described.*

Intelligence is built-in - will  support your QR-invoicing for a smooth execution.
 - Exactness of input data is always a concern !
 - Script will tell you, if any variable is not being parsed "as expected" (-v for verbose)
 - Script does also some URLENCODE / HTMLESCAPING (iconv and other tricks)

*Good data is correct data*

Address management is probably the biggest data-quality challenge for every postal service in the world. Some countries do really put incredible effort in tracking updates, continuosly cleaning up their databases, eventually describing Postcode borders in GIS and/or KML formats (also Swiss Post offer those archives publicly online). Always refer to QR-Rechnung Postfinance validation rules in case of doubts.

## Invocation - self describing help
```
Please invoke CURL script with ALL needed API parameters

Syntax:
 curl-rest.sh -I <CRED.IBAN.19> -F <out.filename> -d <out.dirname> [-R <DEBT.ref.26>] [-G <DEBT.msg>] [-M <DEBT.amount.8.2>]
   -b <CRED.name> -a <CRED.addr> -n <CRED.addrn> -p <CRED.postcode> -t <CRED.town> -c <CRED.currency> -C <CRED.country>
   -D <DEBT.name> -A <DEBT.addr> -N <DEBT.addrn> -P <DEBT.postcode> -T <DEBT.town> -x <DEBT.currency> -X <DEBT.country>
   
Example:
./curl-rest.sh \
   -I "CH0123456789012345678" -F max.test.pdf -d work/ \
   -b "FANTUZNET" -a "L'Ancienne Route" -n 75 -p 1218 -t "Le-Grand-Saconnex" -c 756 -C 756 \
   -D "Massimiliano+Fantuzzi" -A "Chemin des Clys" -N "11" -P 1293 -T Bellevue -x 756 -X 756 \
   -M 100,01 \
   -R 01234567890123456789012345 -G "Reference: 01234567890123456789012345"

./curl-rest.sh -I CH1709000000124984825 -b "association amicale" -a "chemin des marettes" -n 18 -p 1293 -t "Bellevue" -c CHF -C 756 -D "massimiliano fantuzzi" -A "chemin des clys" -N 11 -P 1293 -T Bellevue -x CHF -X 756 -M 9999999.99 -G "Testing messages" -R 12345678901234567890123456 -d ./work -f aaaa.pdf

Most of the options are mandatory (12/20):

  -I    CERDIOTR IBAN
  -b    CREDITOR Company Name
  -a    CREDITOR street address
  -n    CREDITOR building number/p.o.box
  -p    CREDITOR postcode
  -t    CREDITOR town
  -c    CREDITOR currency
  -C    CREDITOR country

[ -D ]  DEBITOR Name
[ -A ]  DEBITOR street address
[ -N ]  DEBITOR building number/p.o.box
[ -P ]  DEBITOR postcode
[ -T ]  DEBITOR town
  -x    DEBITOR currency
  -X    DEBITOR country

[ -M ]  optional DEBT amount
[ -R ]  optional DEBT reference number (input 26 digits, output 27)
[ -G ]  optional message for the debitor

  -d    output directory (i.e. ./work)
  -f    output filename

[ -v ]  Verbose mode
[ -h ]  Print this help
```
## Notes on input validation
The Swiss Post API will ALWAYS need to strictly validate ( POSTCODE + CITY ) against (Javascript) database both for creditor and debitor.
Please account for temporary lack of accents, spaces, separators support. Try to inspect log.curl.* error logs for details on the failure.
ICONV to be re-added soon (for full unicode support).

## Notes on output 
 - Given the same input data, the process will either always succeed and complete - through idempotent calls - or fail on a given state, surely becaue of a "format error"
 - The "bits" and tags in PDF file itself MAY change as the generation is provided by Postfinance service and MAY be subject to unannounced improvements.
 - QR-code vectorial representation MAY  also change, but I have collected no statistics yet on the subject.

## Deliverables

 - curl.sh: the main wrapper script
 - mod10-rec-universal.py: recursive mod10 calculation to checksum AMOUNT and REFERENCE (and IBAN / POST account in older BVR-no-QR pink slips)
 - OCR_BB.TTF: font - for OCR recognition og the old-style post bulletin - aka BVR
 - countries.dat: list of supported countries. check your contry-code if not not using basic CHF (756) or EUR (978).
 - README: this README file

## TODO
 - [ ] add language full language support via iconv, for German, Italian and French 
 - [x] parse commas and dots, as separators for incoming amount (i.e. to generate a 0.01 CHF payment)
 - [x] separate logging feature
 - [x] more comments, a better README 
 - [ ] add parallelization
 - [x] provide vector export, representation and zoom options
 - [ ] check corner cases with accents, htmlescaping, unicode names
 - [ ] add iconv translator to facilitate htmlescaping / urlencoding

## Additional information and references
The Postfinance webservice prooved to be available 99.9% - as far as my customers reported, with only one glitch once, when the provider changed the API path. 

You can always simulate yourself with the original web-application and underlying API, on Post website:
https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html

Note: the QR facture and the BVR-27 standards are imposed through whole Switzerland Postal Payments starting end-September 2022.
