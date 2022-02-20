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

*The script - being opensource - aims to cover all of the cases, give the different situations when we would emit such QR-Rechnung*

Few examples IRL:
 - a charity organization wants to send open donation demand to list of individuals, and have them registered as PAYEES (so for example, they can offload it from tax-declaration)
 - a solidarity cause like food-collection, want to distribute open letter and flyers, with the QR code for payment, without previous knowledge of donated amount, and donor
 - your company wants to regularly output precise invoices, to existing customers, for example integrating with Filemaker, SAP, Success Factor or other CRM applications.

Note: the QR facture and the BVR-27 standards are imposed through whole Switzerland standards starting from end-September 2022.

NOTE2: curl script being anonymized and improved, will be released tonight.
