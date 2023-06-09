#!/bin/bash

#https://www.ubs.com/ch/fr/corporates/payment-solutions/payments/qr-portal.html
#https://qrbill.ubs.com/app/CAL/
#CH340023623611020540L - original
#CH103000523611020540L - QR version

IBAN=CH340023623611020540L
IBAN_QR=CH103000523611020540L

#curl -kviS -L 'https://qrbill.ubs.com/app/CAL/' \
#  -b c0.c \
#  -c c1.c \
#  -H 'Cache-Control: no-cache' \
#  -H 'Connection: keep-alive' \
#  -H 'Sec-Fetch-Dest: empty' \
#  -H 'Sec-Fetch-Mode: cors' \
#  -H 'Sec-Fetch-Site: same-origin' \
#  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36'

#curl -kviS -L 'https://qrbill.ubs.com/app/CAL/main#mainForm' \
#  -b c0.c \
#  -c c1.c \
#  -H 'Cache-Control: no-cache' \
#  -H 'Connection: keep-alive' \
#  -H 'Sec-Fetch-Dest: empty' \
#  -H 'Sec-Fetch-Mode: cors' \
#  -H 'Sec-Fetch-Site: same-origin' \
#  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36'

#fetch("https://qrbill.ubs.com/app/B80/swiss_qr/qr_bill_portal/access", {
#  "headers": {
#    "accept": "application/json, text/plain, */*",
#    "accept-language": "en-US,en;q=0.9,fr;q=0.8,it;q=0.7",
#    "content-type": "application/json",
#    "sec-ch-ua": "\" Not A;Brand\";v=\"99\", \"Chromium\";v=\"104\"",
#    "sec-ch-ua-mobile": "?0",
#    "sec-ch-ua-platform": "\"Linux\"",
#    "sec-fetch-dest": "empty",
#    "sec-fetch-mode": "cors",
#    "sec-fetch-site": "same-origin"
#  },
#  "referrer": "https://qrbill.ubs.com/app/CAL/main",
#  "referrerPolicy": "strict-origin-when-cross-origin",
#  "body": "{\"uuid\":\"cd895636-c7d7-4512-8d5c-47644939403f\",\"area\":\"BASIC\"}",
#  "method": "POST",
#  "mode": "cors",
#  "credentials": "include"
#});


curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/qr_bill_portal/access' \
  -b c1.c \
  -c c0.c \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '{"uuid":"d895636-c7d7-4512-8d5c-47644939403f","area":"BASIC"}' \
  --compressed

curl -kviS 'https://qrbill.ubs.com/app/CAL/' \
  -b c0.c \
  -c c1.c \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36'

# references
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \
curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/validate/reference/' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -b c1.c \
  -c c0.c \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '{"refType":"IBAN","ref":"'$IBAN'"}' \
  --compressed

# ubs_iid
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \
curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/iban/contains/ubs_iid/' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -b c0.c \
  -c c1.c \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw "$IBAN" \
  --compressed

# swiss_qr/qr_excel/to_swiss_qr_bills
# swiss_qr/qr_image/to_text

# to_qr_iban
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \

curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/convert/iban/to_qr_iban' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -b c1.c \
  -c c0.c \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="104"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Linux"' \
  --data-raw "$IBAN" \
  --compressed

# from_iban
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \

# invoiceNr: date + progressive variable
curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/calculate/qr_ref/from_iban' \
  -b c0.c \
  -c c1.c \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '{"iban":"'$IBAN_QR'","invoiceNr":"2208110001"}' \
  --compressed

# input_channel
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \

# uuid: 
curl -kviS 'https://qrbill.ubs.com/app/B80/swiss_qr/qr_bill_portal/input_channel' \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Type: application/json' \
  -b c1.c \
  -c c0.c \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '{"uuid":"554975a9-255e-4294-8986-e9db361e2ee5","area":"BASIC","channel":"MANUAL"}' \
  --compressed

cat c0.c
cat c1.c
exit 127

# pdf invoice download
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \

# ustrd: 2208110001 -> date + progressiv number
# ref: 302361102050400022081100017 -> something + ustrd + mod10
# uuid: 

curl -kviS -L 'https://qrbill.ubs.com/app/B80/swiss_qr/bill/pdf' \
  -o /tmp/test1.pdf \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Language: en-US' \
  -H 'Content-Type: application/json' \
  -b c1.c \
  -c c0.c \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '{"qrBills":[{"swissQr":{"header":{"qrType":"SPC","version":"0200","coding":"1"},"cdtrInf":{"IBAN":"'$IBAN_QR'","cdtr":{"adrType":"S","name":"Massimiliano Fantuzzi","strtNmOrAdrLine1":"chemin de la Chenaie","bldgNbOrAdrLine2":"17","pstCd":"1293","twnNm":"Bellevue","ctry":"CH"}},"ultmtCdtr":null,"ccyAmt":{"amt":"100,99","ccy":"CHF"},"ultmtDbtr":{"adrType":"S","name":"","strtNmOrAdrLine1":null,"bldgNbOrAdrLine2":null,"pstCd":"","twnNm":"","ctry":""},"rmtInf":{"tp":"QRR","ref":"302361102050400022081100017","addInf":{"ustrd":"Number: 2208110001 ","trailer":"EPD","strdBkgInf":""}},"altPmtInf":{"altPmt":[""]}},"receipt":{"payableTo":"","telefoneNumber":"","email":"","clientIdentification":"","additionalDetails":"","invoiceDate":"","receiver":"","subjectLine":"","invoiceDetails":""}}],"access":{"uuid":"554975a9-255e-4294-8986-e9db361e2ee5","area":"BASIC","channel":"MANUAL"},"printTwoPaymentSlipsOnOnePage":false,"withPerforation":true,"zippedSinglePagePdfOutput":false,"logo":{"contentType":"","fileName":"","content":""}}' \
  --compressed

# pdf statement download
# -H 'Cookie: campID=SEM-BRAND-CH-FRA-GOOGLE-BRAND-ANY-ubs-e-c; geo-country=CH; AMCVS_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1; NavLB_EBCH=ebanking-ch2.ubs.com; ubslang=it-CH; uwrlocale=it; s_cc=true; sat_track=true; BIGipServer~pa-1469-ubs0bss0001csa21ad1286~pl-ubs0-www-tmp.inter.cmuintra.ch-https=rd1469o00000000000000000000ffff0a6cf624o443; s_gpv_url2=https%3A%2F%2Fwww.ubs.com%2Fch%2Fen.html; usy46gabsosd=UBSCSA__1092502341_1613416959422_1613416959490_2655; UBSCSAkey=eee39d2c0da74d3ea08d99bf88f81559; AMCV_73FAC51D54C72AE50A4C98BC%40AdobeOrg=1228199804%7CMCIDTS%7C18674%7CMCMID%7C87002445720508656730969622812473235813%7CMCAAMLH-1614021760%7C6%7CMCAAMB-1614021760%7CRKhpRz8krg2tLO6pguXWp5olkAcUniQYPHaMWWgdJ3xzPWQmdj0y%7CMCOPTOUT-1613424160s%7CNONE%7CMCAID%7CNONE%7CvVersion%7C4.4.0%7CMCCIDH%7C-615244033; s_ht=1613416963295; s_hc=2%7C0%7C0%7C0%7C0' \
curl -kviS -L 'https://qrbill.ubs.com/app/B80/swiss_qr/confirmation/pdf' \
  -o /tmp/test2.pdf \
  -b c1.c \
  -c c0.c \
  -H 'Accept: application/json, text/plain, */*' \
  -H 'Cache-Control: no-cache' \
  -H 'Connection: keep-alive' \
  -H 'Content-Language: en-US' \
  -H 'Content-Type: application/json' \
  -H 'Origin: https://qrbill.ubs.com' \
  -H 'Pragma: no-cache' \
  -H 'Referer: https://qrbill.ubs.com/app/CAL/main' \
  -H 'Sec-Fetch-Dest: empty' \
  -H 'Sec-Fetch-Mode: cors' \
  -H 'Sec-Fetch-Site: same-origin' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.5112.79 Safari/537.36' \
  --data-raw '[{"header":{"qrType":"SPC","version":"0200","coding":"1"},"cdtrInf":{"IBAN":"CH103000523611020540L","cdtr":{"adrType":"S","name":"Massimiliano Fantuzzi","strtNmOrAdrLine1":"chemin de la Chenaie","bldgNbOrAdrLine2":"17","pstCd":"1293","twnNm":"Bellevue","ctry":"CH"}},"ultmtCdtr":null,"ccyAmt":{"amt":"100,99","ccy":"CHF"},"ultmtDbtr":{"adrType":"S","name":"","strtNmOrAdrLine1":null,"bldgNbOrAdrLine2":null,"pstCd":"","twnNm":"","ctry":""},"rmtInf":{"tp":"QRR","ref":"302361102050400022081100017","addInf":{"ustrd":"Number: 2208110001 ","trailer":"EPD","strdBkgInf":""}},"altPmtInf":{"altPmt":[""]}}]' \
  --compressed

sed 's/["{}\]//g' /tmp/test1.pdf | sed 's/,/\n/g' | sed 's/content://p' | tail -1 | base64 -d > /tmp/test1.new.pdf
sed 's/["{}\]//g' /tmp/test2.pdf | sed 's/,/\n/g' | sed 's/content://p' | tail -1 | base64 -d > /tmp/test2.new.pdf
rm -v c0.c c1.c
