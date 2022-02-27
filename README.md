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
1. a charity organization wants to send open "donation demand" to list of known individuals
2. a solidarity cause for food-collection want to distribute open letter and flyers - along with the QR code - without previous knowledge of donated amount of nor the donor's coordinates (i.e. public events)
3. your company wants to regularly output precise invoices to existing customers - integrating with Filemaker, SAP, Success Factor or other CRM applications.

## Purpose / Invocation
*The script - opensource - aims to cover all of the cases. Always refer to QR-Rechnung Postfinance validation rules*

Intelligence is built-in - will  support your QR-invoicing for a smooth execution.
 - Script will tell you, if any variable is not being parsed "as expected" (--verbose)
 - Script does also some URLENCODE / HTMLESCAPING but exactness of input data is always a concern !
 - Given the same input data, the process will either always succeed and complete - through idempotent calss - or fail on a given state, surely becaue of a "format error"
 - The bits & bytes in the PDF file itself may change, as the generation is done by Postfinance backends and maybe subject to unannounced improvements.
 - QR-code appereance may also change, but on this I have no statistics yet.

Address management is one of the biggest challenges for every postal service in the world. Some countries do really put incredible effort in tracking updates, continuosly cleaning up their databases, even geolocalizing different borders (Swiss Post offers those coordinate archives publicly in some KML repo). (TB updated)

In the case of this API to Swiss Post - the POSTCODE and CITY coordinates are strictly validated against (Javascript-available) database.
Please account for accents, spaces, separators.
Try to inspect curl.error logs for details on the failure.

Good data is correct data.

## Features - self describing help
```
Please invoke CURL script with ALL needed API parameters

Syntax: curl.sh -I <CRED.IBAN> [-M <DEBT.amount>] 
   -b <CRED.name> -a <CRED.addr> -n <CRED.addrn> -p <CRED.postcode> -t <CRED.town> -c <CRED.currency> -C <CRED.country>
   -D <DEBT.name> -A <DEBT.addr> -N <DEBT.addrn> -P <DEBT.postcode> -T <DEBT.town> -x <DEBT.currency> -X <DEBT.country>
     
Example:
./curl.sh -I "CH<19 digits>" -b "FANTUZNET" -a "La Ancienne Route" -n 75 -p 1218 -t "Le-Grand-Saconnex" -c 756 -C 756 -D "Masimiliano+Fantuzzi" -A "Chemin+des+Clys" -N "11" -x 756 -X 756 -P 1293 -T Bellevue -F max.test.pdf -d work/ -R "<26 digits>" -G testmeout

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

[-M ]   optional DEBT amount
[-R ]   optional DEBT reference number (input 26 digits, output 27)
[-G ]   optional message for the debitor

 -d     output directory (i.e. $/work)
 -F     output filename

 -v     Verbose mode.
 -h     Print this Help.

```

## TODO
 - add language full language support via iconv, for German, Italian and French 
 - parse commas and dots, as separators for incoming amount (i.e. to generate a 0.01 CHF payment)
 - separate logging feature
 - more comments, a better README 
 - add parallelization

## Additional information and references
The Postfinance webservice prooved to be available 99.9% - as far as my customers reported, with only one glitch once, when the provider changed the API path. 

You can always simulate yourself with the original web-application and underlying API, on Post website:
https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html

Note: the QR facture and the BVR-27 standards are imposed through whole Switzerland standards starting from end-September 2022.
