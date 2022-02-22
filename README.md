# QR-Rechnung
Postfinance QR Invoicing - Shell Script Based on CURL &amp; Python

## Overview
Simple wrapper-script which enables every Swiss company or individual - generating valid QR-invoice using public Postfinance API.

Check all of the Creditor and Debitor mandatory parameters, along with few optional/dynamic ones (i.e. the amount of the invoice itself).

The process of generating QR-invoice via Swiss Postfinance service has to follow one of the different paths described below, in order to end up with a valid payment request (replacing old pink/yellow BVR). Here the tracked cases:
 - [x] payment to CREDITOR with an AMOUNT and a specific DEBITOR
 - [x] payment to CREDITOR with an AMOUNT but no specific DEBITOR information
 - [x] payment to CREDITOR without any precise AMOUNT, addressed to specific DEBITOR
 - [x] payment to CREDITOR without any precise AMOUNT and without specific DEBITOR information

Depending on the above needs - configurable via script option - all of the basic input variables to be used in API/POST will be automatically adjusted. 

Few examples IRL:
 - a charity organization wants to send open donation demand to list of individuals, and have them registered as PAYEES (so for example, they can offload it from tax-declaration)
 - a solidarity cause like food-collection, want to distribute open letter and flyers, with the QR code for payment, without previous knowledge of donated amount, nor the donor's coordinates (i.e. charity, public events)
 - your company wants to regularly output precise invoices, to existing customers, for example integrating with Filemaker, SAP, Success Factor or other CRM applications.

## Usage / Invocation
*The script - opensource - aims to cover all of the cases. Always refer to QR-Rechnung Postfinance validation rules*

Address management is one of the biggest challenges for every postal service in the world. Some countries do really put incredible effort in tracking updates, geolocalizing borders (Swiss Post has those coordinate data publicly  available in some KML repo). (TB updated)

In the case of this API to Swiss Post - the POSTCODE and CITY coordinates are strictly validated against (Javascript-available) database.
Please account for accents, spaces, separators. Good data is correct data. Try to inspect curl.error logs for details on the failure.

A little intelligence is built-in my helper script, and would try to support your QR-invoicing for a smooth execution.
 - Script will tell you, if any variable is not being parsed "as expected"
 - Script does also some URLENCODE / HTMLESCAPING but exactness of input data is always a concern !
 - Given the same input data, the process will either always succeed and complete - through idempotent calss - or fail on a given state, surely for a format error.

## Features - self describing help
```
Please invoke CURL script with ALL needed API parameters

Syntax: curl.sh [-M <DEBT.amount>]
   -T <CRED.name> -I <CRED.IBAN> -a <CRED.addr> -n <CRED.addrn> -p <CRED.postcode> -t <CRED.town> -c <CRED.currency> -C <CRED.country>
   -D <DEBT.name> -A <DEBT.addr> -N <DEBT.addrn> -P <DEBT.postcode> -W <DEBT.town> -x <DEBT.currency> -X <DEBT.country>
   
Most of the options are mandatory:

 -I     CERDIOTR IBAN
 -b     CREDITOR Company Name
 -a     CREDITOR street address
 -n     CREDITOR building number/p.o.box
 -p     CREDITOR postcode
 -t     CREDITOR town
 -c     CREDITOR currency
 -C     CREDITOR country

 -D     DEBITOR Name
 -A     DEBITOR street address
 -N     DEBITOR building number/p.o.box
 -P     DEBITOR postcode
 -T     DEBITOR town
 -x     DEBITOR currency
 -X     DEBITOR country

[-M     DEBITOR amount]
[-R     DEBITOR reference number] (input 26 digits, output 27)
[-G     DEBITOR message]

 -F     output filename

 -h     Print this Help.
 -v     Verbose mode.
```


## TODO
 - add language full language support via iconv, for German, Italian and French 
 - parse commas and dots, as separators for incoming amount (i.e. to generate a 0.01 CHF payment)
 - separate logging feature
 - more comments, a better README 

## Additional information and references
The Postfinance webservice prooved to be available 99.9% - as far as my customers reported, with only one glitch once, when the provider changed the API path. 

You can always simulate yourself with the original web-application and underlying API, on Post website:
https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html

Note: the QR facture and the BVR-27 standards are imposed through whole Switzerland standards starting from end-September 2022.
