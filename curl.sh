#!/bin/bash

## parse CSV as loop, just for reference
#time while IFS=";" read -r linenumber field1 field2 f3 f4 f5; do ./curl.sh "$field1" "$field2" "$f3" "$f4" "$f5" 10 CHF CH $linenumber; done < <(head -5 fichier.input)

## one of the many different ways to invoke a script within FileMaker
# do shell script "./mod10-rec.py" & space & "'-x'" & space & "'01234560000012345020201234'"

#Set locale (i.e. French, Swiss-French, German, Swiss-German, Italian, etc)
#export LC_ALL="fr_CH.ISO8859-1"
#export LANG="fr_CH.ISO8859-1"

htmlEscape() 
{
    local s
    s=${1//&/&amp;}
    s=${s//</&lt;}
    s=${s//>/&gt;}
    s=${s//'"'/&quot;}
    printf -- %s "$s"
}

usage() 
{
   echo -e "\nPlease invoke CURL script with ALL needed API parameters\n"
   echo -e "Syntax: $(basename $0) [-M <DEBT.amount>]
   -T <CRED.name> -I <CRED.IBAN> -a <CRED.addr> -n <CRED.addrn> -p <CRED.postcode> -t <CRED.town> -c <CRED.currency> -C <CRED.country>
   -D <DEBT.name> -A <DEBT.addr> -N <DEBT.addrn> -P <DEBT.postcode> -W <DEBT.town> -x <DEBT.currency> -X <DEBT.country>
   "
   echo "Most of the options are mandatory:"
   echo
   echo " -I     CERDIOTR IBAN"
   echo " -b     CREDITOR Company Name"
   echo " -a     CREDITOR street address"
   echo " -n     CREDITOR building number/p.o.box"
   echo " -p     CREDITOR postcode"
   echo " -t     CREDITOR town"
   echo " -c     CREDITOR currency"
   echo " -C     CREDITOR country"
   echo
   echo " -D     DEBITOR Name"
   echo " -A     DEBITOR street address"
   echo " -N     DEBITOR building number/p.o.box"
   echo " -P     DEBITOR postcode"
   echo " -T     DEBITOR town"
   echo " -x     DEBITOR currency"
   echo " -X     DEBITOR country"
   echo
   echo "[-M     DEBITOR amount]"
   echo "[-R     DEBITOR reference number] (input 26 digits, output 27)"
   echo "[-G     DEBITOR message]"
   echo
   echo " -F     output filename"
   echo
   echo " -h     Print this Help."
   echo " -v     Verbose mode."
   echo
}

while getopts "b:I:a:n:p:t:c:C:D:A:N:M:P:T:x:X:R:G:F:h" option; do
   echo "$option -> - "$OPTIND" : " $OPTARG
   case $option in
      b) # company title
         CRED_NAME=$OPTARG
         ;;
      I) # IBAN
         CRED_IBAN=$OPTARG
         ;;
      a) # street address
         CRED_ADDRA=$OPTARG
         ;;
      n) # building address number
         CRED_ADDRN=$OPTARG
         ;;
      p) # postcode
	 CRED_NPA=$OPTARG
         ;;
      t) # town
	 CRED_VILLE=$OPTARG
         ;;
      c) # country (default 756)
	 CRED_COUNTRY=$OPTARG
         ;;
      C) # currency (default 756)
	 CRED_ETAT=$OPTARG
         ;;
      D) # DEBITOR company title / PAYEE / DEBTOR
         DEB_NAME=$OPTARG
         ;;
      A) # DEBITOR street address
         DEB_ADDRA=$OPTARG
         ;;
      N) # DEBITOR building address number
         DEB_ADDRN=$OPTARG
         ;;
      M) # amount (or 0 if no amount)
         DEB_AMT=$OPTARG
         ;;
      P) # DEBITOR postcode
         DEB_NPA=$OPTARG
         ;;
      T) # DEBITOR town
         DEB_VILLE=$OPTARG
         ;;
      x) # debitor currency
	 echo "$option" $OPTIND $OPTARG
         DEB_CURR=$OPTARG
         ;;
      X) # debitor country
	 echo "$option" $OPTIND $OPTARG
         DEB_COUNTRY=$OPTARG
         ;;
      R) # REF number
         DEB_REF=$OPTARG
	 if [[ $(echo -n $DEB_REF | wc -c) != "26" ]]; then echo "-- Reference must be 26 digits"; exit 127; fi
         ;;
      G) # REF message
         DEB_MSG=$OPTARG
         ;;
      F) # filename
	 INAME=$OPTARG
         ;;
      *) echo "Error: Invalid option"
	 usage
	 shift
	 break
	 ;;
   esac
done
shift "$((OPTIND-1))"

#if [ ! -f "$BASE/eeee.pdf" ]; then echo "CHECK MONTANT D'ABORD"; exit 1; fi
BASE=/home/max/Downloads/PDF-facture

CRED_NAME=$(echo "$CRED_NAME" | tr ' ' '+')
CRED_ADDR=$(echo "$CRED_ADDR" | tr ' ' '+')
CRED_ADDRA=$(echo "$CRED_ADDRA" | tr ' ' '+')

DEB_NAME=$(echo "$DEB_NAME" | tr ' ' '+')
DEB_ADDR=$(echo "$DEB_ADDR" | tr ' ' '+')
DEB_ADDRA=$(echo "$DEB_ADDRA" | tr ' ' '+')
#DEB_ADDRA=$DEB_ADDR
#DEB_ADDRN=$(echo $DEB_ADDR | awk -F ',' '{print $1}')
#DEB_ADDRN=$3
#DEB_NPA=$4
DEB_VILLE=$(echo "$DEB_VILLE" | tr ' ' '+')
DEB_ETAT="SUISSE"

#if [ -s $DEB_AMT ]; then true; else DEB_AMT=$(echo "$6" | tr -d \'); fi
if [[ -z $DEB_AMT || $DEB_AMT -lt 0,02 ]]; then
  DEB_AMT=''
  echo "DEB_AMT_CRC to script: ZERO AMOUNT INVOICE" | tee -a amt.txt >> $BASE/june.log.txt
else
  # Leading 010 - mandatory prefix to 9 more digits and control digit (total 13 and field-sep-char '>' in old BVR)
  DEB_AMT_CRC=$(printf "01%010d" $DEB_AMT)
  echo "DEB_AMT: " $DEB_AMT >> $BASE/amt.txt
  echo "DEB_AMT_CRC printf: " $DEB_AMT_CRC | tee -a $BASE/amt.txt
  #DEB_AMT_CRC=$(perl -e "printf('01%0.2d\n', $DEB_AMT)")
  #echo "DEB_AMT_CRC perl: " $DEB_AMT_CRC >> $BASE/amt.txt
  DEB_AMT_TMP=$(echo $DEB_AMT | tr ',' '.' )
  DEB_AMT_CRC=$(perl -e "printf('010%010.2f', $DEB_AMT_TMP)" | tr -d ',.\n')
  echo "DEB_AMT_CRC to script: "$DEB_AMT_CRC | tee -a amt.txt
MOD10_M=$($BASE/mod10-rec-montant.py -x $DEB_AMT_CRC)
MON_REF_9=$MOD10_M
fi

if [[ -n $DEB_REF ]]; then 
  MOD10_R=$($BASE/mod10-rec-long.py -x $DEB_REF)
  DEB_REF_27=$MOD10_R
  echo "DEB_REF_27 to script: "$DEB_REF_27 | tee -a amt.txt
fi

DEB_MSG=$(echo -n "Charity Org "$DEB_MSG" "$DEB_REF_27 | tr ' ' '+')

#if [ "$#" -eq 0 ]; then
#  echo -e "\nMissing some of the CREDITOR or DEBITOR information.\n"
#  echo -e "CRED-INFO: 1.NAME-SURNAME/COMPANY 2.STREET-ADDR 3.BUILDING-ADDR-N/POBOX\n4.POSTCODE 5.CITY\n6.IBAN     7.CURRENCY 8.COUNRTY"
#  echo -e "DEBT-INFO: 1.NAME-SURNAME         2.STREET-ADDR 3.BUILDING-ADDR-N/POBOX\n4.POSTCODE 5.CITY\n[6.AMOUNT] 7.CURRENCY 8.COUNTRY [9.FILENAME]"
#  #usage
#fi

if [[ $DEB_CURR = 756 ]]; then
  true
else
  if [[ $DEB_CURR == "EUR" || $DEB_CURR == 'eur' ]]; then DEB_CURR=978; fi # EUR 978, CHF 756
  if [[ $DEB_CURR == "CHF" || $DEB_CURR == 'chf' ]]; then DEB_CURR=756; fi # EUR 978, CHF 756
  echo "UNKNOWN CURRENCY. DEVISE PAS CONNUE. ($7, $@)"; exit 2
fi

if [[ $DEB_COUNTRY = 756 ]]; then true; else
  if [[ $DEB_COUNTRY == "CH" || $DEB_COUNTRY == 'ch' ]]; then
    DEB_COUNTRY=756 # FR 250, CH 756, IT 380
  else
    if [[ $DEB_COUNTRY == "FR" || $DEB_COUNTRY == 'fr' ]]; then
      DEB_COUNTRY=250 # FR 250, CH 756, IT 380
    else
      if [[ $DEB_COUNTRY == "IT" || $DEB_COUNTRY == 'it' ]]; then
        DEB_COUNTRY=380 # FR 250, CH 756, IT 380
      else
        echo "UNKNOWN COUNTRY. PAYS PAS CONNU."
        exit 2
      fi
    fi
  fi
fi

FNAME=$BASE/work/$INAME

echo "-------------------------------"
echo START | tee -a $BASE/amt.txt
echo "-------------------------------"
echo C.name : $CRED_NAME
echo C.iban : $CRED_IBAN
echo C.addr : $CRED_ADDR
echo C.addra: $CRED_ADDRA
echo C.addrn: $CRED_ADDRN
echo C.postc: $CRED_NPA
echo C.town : $CRED_VILLE
echo C.state: $CRED_ETAT
echo C.state: $CRED_COUNTRY
echo C.curr : $DEB_CURR
echo C.currc: $DEB_COUNTRY

###DEB_REF=$(grep -a '/Title' $BASE/eeee.pdf | sed -n 's/^\(.*\).*\/Title/\1/p' | sed -n 's/^\(.*\).*)(/\1----/p' | sed -n 's/^\(.*\).*)>>/\1----/p' | awk -F '----' '{print $2}')
#DEB_AMT=$(grep -a '/Subj' $BASE/eeee.pdf | sed -n 's/^\(.*\).*\/Subject/\1/p' | sed -n 's/^\(.*\).*)(/\1----/p' | sed -n 's/^\(.*\).*)\/Ti/\1----/p' | awk -F '----' '{print $2}')

#DEB_AMT_TWO=$(printf "%.2f" $DEB_AMT)

#echo "AMT " $DEB_AMT >> $BASE/june.log.txt
#echo "AMT_TWO " $DEB_AMT_TWO >> $BASE/june.log.txt
#printf "AMT f %.2f\n" $DEB_AMT >> $BASE/june.log.txt
#printf "AMT d %.2d\n" $DEB_AMT >> $BASE/june.log.txt
#perl -e "printf('AMT f %.2f\n', $DEB_AMT)" >> $BASE/june.log.txt

#DEB_AMT_CRC=$(printf "01%010d" $DEB_AMT)
#DEB_AMT_CRC=$(echo $DEB_AMT | tr -d ',.' | printf "01%08d")
#DEB_AMT_CRC_TWO=$(printf "01%08d" $DEB_AMT)
#echo "DEB_AMT_CRC to script: "$DEB_AMT_CRC >> $BASE/june.log.txt
#echo "DEB_AMT_CRC_TWO to script: "$DEB_AMT_CRC >> $BASE/june.log.txt

###DEB_NAME=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n' | awk -F '##' '{print $2}' | tr -d '\n\r' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/^+//' | sed 's/+$//')
###DEB_ADDR=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $3}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//')
###DEB_ADDRA=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $3}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | awk -F ',' '{print $2}' | cut -c  1-)
####DEB_ADDRN=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $4}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | awk -F ',' '{print $2}' | cut -c  1-)
###DEB_NPA=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')' | awk -F '##' '{print $4}' | tr -d '[:alpha:]' | tr -d ' \r\n')
###DEB_VILLE=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')' | awk -F '##' '{print $5}' | sed 's/^ //' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | sed 's/+$//')
###DEB_AMT=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | awk -F '##' '{print $6}' | tr -d '[:alpha:]' | tr -d ' \r\n')
###echo "DEB_AMT to script: "$DEB_AMT >> $BASE/june.log.txt

echo "-------------------------------"
echo D.name : $DEB_NAME | tee -a $BASE/amt.txt
echo D.addr : $DEB_ADDR | tee -a $BASE/amt.txt
echo D.addra: $DEB_ADDRA | tee -a $BASE/amt.txt
echo D.addra: $DEB_ADDRA
echo D.addrn: $DEB_ADDRN | tee -a $BASE/amt.txt
echo D.NPA: : $DEB_NPA | tee -a $BASE/amt.txt
echo D.town : $DEB_VILLE | tee -a $BASE/amt.txt

echo D.ref: : $DEB_REF | tee -a $BASE/amt.txt 
echo D.ref  : $DEB_REF_27 | tee -a $BASE/amt.txt
echo D.amt  : $MON_REF_9 | tee -a $BASE/amt.txt
echo D.amt  : $DEB_AMT | tee -a $BASE/amt.txt
echo D.amtc : $DEB_AMT_CRC | tee -a $BASE/amt.txt
echo D.curr : $DEB_CURR
echo D.curcc: $DEB_COUNTRY

echo "-------------------------------" | tee -a $BASE/amt.txt
echo INAME  : $INAME
echo FNAME  : $FNAME
echo TS     : $TS

## PRE-GET
curl -s -L -c $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html' > $BASE/log.curl.acquire

SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.acquire | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.acquire | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
echo step1: $SP - $FP
	
## CREDITEUR
# OLD Swill Post URL left for reference. If script fails, something has changed on the service layer.
# curl -s -c $BASE/cookie.test -b $BASE/cookie.pre 'https://www.postfinance.ch/fr/entreprises/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
curl -s -c $BASE/cookie-pre -b $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
--compressed \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'qrBillInformation.creditorInformation.name='$CRED_NAME'&qrBillInformation.creditorInformation.iban='$CRED_IBAN'&qrBillInformation.creditorInformation.street='$CRED_ADDRA'&qrBillInformation.creditorInformation.houseNumber='$CRED_ADDRN'&qrBillInformation.creditorInformation.zipCode='$CRED_NPA'&qrBillInformation.creditorInformation.city='$CRED_VILLE'&qrBillInformation.creditorInformation.country='$CRED_COUNTRY'&nextPaymentInformation=&_sourcePage='$SP'&__fp='$FP 2>$BASE/log.curl.crediteur >$BASE/log.curl.recipient

SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.recipient | awk -F 'value' '{print $2}' | cut -c 2- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.recipient | awk -F 'value' '{print $2}' | cut -c 2- | tr -d '<>"' | sed 's/=/%3D/g')
echo step2: $SP - $FP

## CALCULATE DEB_REF CRC without amount
curl -s -b $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do?calculateQrReference=&qrReference='$DEB_REF \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
-H 'Accept: */*' \
--compressed \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Connection: keep-alive' 2>&1 | tee $BASE/crc | grep '{ "qrReference" : "' | sed -n 's/{ "qrReference" : "\(.*\)" }/\1/p' | tr -d ' ' | tail -1 > $BASE/crc.final

# old regex / other API
# | grep -A 1 'div id="calculatedQrReference"' | tail -1 > $BASE/crc.final

## MONTANT ET REFERENCE DU PAIMENT
curl -s -b $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
--compressed \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'qrBillInformation.paymentInformation.amount='$DEB_AMT'&qrBillInformation.paymentInformation.currency='$DEB_CURR'&qrBillInformation.paymentInformation.qrReference='$DEB_REF_27'&qrBillInformation.paymentInformation.message='$DEB_MSG'&nextDebtorInformation=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.montant

# no paymentInformation.qrReference
#--data-raw 'qrBillInformation.paymentInformation.amount='$DEB_AMT'&qrBillInformation.paymentInformation.currency='$DEB_CURR'&qrBillInformation.paymentInformation.message='Charity+Organization+123+example.com'&nextDebtorInformation=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.montant

SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.montant | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.montant | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
echo step3: $SP - $FP

## DEBITEUR
curl -s -b $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
--compressed \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'qrBillInformation.debtorInformation.addInformation=1&qrBillInformation.debtorInformation.name='$DEB_NAME'&qrBillInformation.debtorInformation.street='$DEB_ADDRA'&qrBillInformation.debtorInformation.houseNumber='$DEB_ADDRN'&qrBillInformation.debtorInformation.zipCode='$DEB_NPA'&qrBillInformation.debtorInformation.city='$DEB_VILLE'&qrBillInformation.debtorInformation.country='$DEB_COUNTRY'&nextSummary=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.debiteur
SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.debiteur | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.debiteur | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
echo step4: $SP - $FP

## FINALIZE
curl -s -b $BASE/cookie-pre 'https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
--compressed \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'nextQrBillCreated=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.finalize

TS=$(grep '<input id="downloadUrl" type="hidden" value="/pfch/web/qrbill/Index.do?createQrBill' $BASE/log.curl.finalize | awk -F 'time' '{print $2}' | tr -d '=' | awk -F '"' '{print $1}')
echo TS next: $TS

if [ $INAME ]; then OUTNAME=$BASE/$INAME; else OUTNAME=$BASE/facture.pdf; fi
## DOWNLOAD
curl -s -b $BASE/cookie-pre 'https://www.postfinance.ch/pfch/web/qrbill/Index.do?createQrBill&time='$TS \
-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:79.0) Gecko/20100101 Firefox/79.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: en-US,en;q=0.5' \
--compressed \
-o $OUTNAME \
-H 'Referer: https://www.postfinance.ch/fr/assistance/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' 2>$BASE/log.curl.download-error

echo -e "LAST RUN:" $(date) "\n" | tee $BASE/run.csv

#echo $@ | tee -a $BASE/test-2.csv
echo -n $MOD10_R | tee -a $BASE/crc-ref.csv > $BASE/crc-ref.html
echo -n $MOD10_M | tee -a $BASE/crc-montant.csv > $BASE/crc-montant.html

# just to verify visually
xdg-open $OUTNAME &
#cp -v $OUTNAME $BASE/work/$(basename $OUTNAME)
#cp -v $BASE/BVR.pdf $BASE/work/.

echo "-------------------------------"
echo -e -n "BILLING COMPLETE: "$DEB_REF_27"_"$DEB_AMT"_"$DEB_CURR"_"$DEB_COUNTRY"\n" | tee -a $BASE/amt.txt >> $BASE/run.csv
exit 0

