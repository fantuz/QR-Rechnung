# QR-Rechnung
Postfinance QR Invoicing - Helper Script Based on CURL Bash &amp; Python


Simple wrapper-script which enables Swiss and neighboring SMB to generate valid QR-invoice using public Postfinance API.
Scrpt expects 8 mandatory parameters, and few optional/dynamic ones as the output-filename.

The process of generating QR-invoice in Swiss context may follow few different paths, before ending up in a valid payment request (replacing old pink/yellow BVR).
Here the tracked cases:
 - payment to CREDITEE with NO-AMOUNT and NO-PAYEE
 - payment to CREDITEE with AMOUNT and NO-PAYEE
 - payment to CREDITEE with NO-AMOUNT and valid PAYEE

Depending on the above needs - configurable via script option - all of the basic input variables to be used in API/POST will be automatically adjusted. 

Few examples IRL:
 - a charity organization wants to send open donation demand to list of individuals, and have them registered as PAYEES (so for example, they can offload it from tax-declaration)
 - a solidarity cause like food-collection, want to distribute open letter and flyers, with the QR code for payment, without previous knowledge of donated amount, and donor
 - your company wants to regularly output precise invoices, to existing customers, for example integrating with Filemaker, SAP, Success Factor or other CRM applications.

*The script - opensource - aims to cover all of the cases. Always refer to QR-Rechnung Postfinance validation rules*

Address management is one of the biggest challenges for every postal service in the world. Some countries do really put incredible effort in tracking updates, geolocalizing borders (Swiss Post has those coordinate data publicly  available in some KML repo). (TB updated)

In the case of this API to Swiss Post - the POSTCODE and CITY coordinates are strictly validated against (Javascript-available) database.
Please account for accents, spaces, separators. Good data is correct data. Try to inspect curl.error logs for details on the failure.

A little intelligence is built-in my helper script, and would try to support your QR-invoicing for a smooth execution.
 - Script will tell you, if any variable is not being parsed "as expected"
 - Script does also some URLENCODE / HTMLESCAPING but exactness of input data is always a concern !
 - Given the same input data, the process will either always succeed and complete - through idempotent calss - or fail on a given state, surely for a format error.

The Postfinance webservice prooved to be available 99.9% - as far as my customers reported, with only one glitch once, when the provider changed the API path. 

You can always simulate yourself with the original web-application and underlying API, on Post website:
https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html

Note: the QR facture and the BVR-27 standards are imposed through whole Switzerland standards starting from end-September 2022.

NOTE2: curl script being anonymized and improved, will be released tonight.
