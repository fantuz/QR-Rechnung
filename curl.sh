#!/bin/bash

##cat liste\ présence_Printemps214.csv | awk -F ',' '{print "./curl.sh -v -I \"CH3409000000120109105\" -b \"Paroisse protestante d-Onex\" -a \"Route de Chancy\" -n 124 -p 1213 -t \"Onex\" -c 756 -C 756 -d ./tmp -f \""$3"_"$2"_"$1"_"$6"_"$7"_"NR".pdf\" -M 0 -x 756 -X 756 -G \"OFFRANDE+2022\" -D \""$8"\" -A \""$4"\" -N \""$5"\" -P \""$6"\" -T \""$7"\""}' | tee print214.sh

VERBOSE_BVR=0
MANDATORY=0
LINUX=0

## parse CSV as loop, just for reference
#time while IFS=";" read -r linenumber field1 field2 f3 f4 f5; do ./curl.sh "$field1" "$field2" "$f3" "$f4" "$f5" 10 CHF CH $linenumber; done < <(head -5 fichier.input)

#Set locale (i.e. French, Swiss-French, German, Swiss-German, Italian, etc)
#export LC_ALL="fr_CH.ISO8859-1"
#export LANG="fr_CH.ISO8859-1"

purify()
{
    echo $@ | tr '	 \/_\n\r' '+'
}

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
    echo -e "\nPlease invoke CURL script with ALL needed API parameters"
    echo -e "
Syntax:
 $(basename $0) -I <CRED.IBAN.19> -F <out.filename> -d <out.dirname> [-R <DEBT.ref.26>] [-G <DEBT.msg>] [-M <DEBT.amount.8.2>]
   -b <CRED.name> -a <CRED.addr> -n <CRED.addrn> -p <CRED.postcode> -t <CRED.town> -c <CRED.currency> -C <CRED.country>
   -D <DEBT.name> -A <DEBT.addr> -N <DEBT.addrn> -P <DEBT.postcode> -T <DEBT.town> -x <DEBT.currency> -X <DEBT.country>
   
Example:
./$(basename $0) \\
   -I \"CH0123456789012345678\" -F max.test.pdf -d work/ \\
   -b \"FANTUZNET\" -a \"L'Ancienne Route\" -n 75 -p 1218 -t \"Le-Grand-Saconnex\" -c 756 -C 756 \\
   -D \"Massimiliano+Fantuzzi\" -A \"Chemin des Clys\" -N \"11\" -P 1293 -T Bellevue -x 756 -X 756 \\
   -M 100,01 \\
   -R 01234567890123456789012345 -G \"Your Reference: $DEB_REF\"

Most of the options are mandatory (10/20):\n"
    echo " -I     CERDIOTR IBAN"
    echo " -b     CREDITOR Company Name"
    echo " -a     CREDITOR street address"
    echo " -n     CREDITOR building number/p.o.box"
    echo " -p     CREDITOR postcode"
    echo " -t     CREDITOR town"
    echo
    echo " -c     CREDITOR currency"
    echo " -C     CREDITOR country"
    echo
    echo " -x     DEBITOR currency"
    echo " -X     DEBITOR country"
    echo
    echo "[ -D ]  DEBITOR Name"
    echo "[ -A ]  DEBITOR street address"
    echo "[ -N ]  DEBITOR building number/p.o.box"
    echo "[ -P ]  DEBITOR postcode"
    echo "[ -T ]  DEBITOR town"
    echo
    echo "[-M ]   optional DEBT amount"
    echo "[-R ]   optional DEBT reference number (input 26 digits, output 27)"
    echo "[-G ]   optional message for the debitor"
    echo
    echo " -d     output directory (i.e. $(dirname $0)/work)"
    echo " -f     output filename"
    echo
    echo " -v     Verbose mode"
    echo " -h     Print this help"
    echo
    exit 127
}

while getopts "b:I:a:n:p:t:c:C:D:A:N:P:T:x:X:M:R:G:d:f:vh" option; do
   if [[ $VERBOSE_BVR -eq 1 ]]; then echo "$option -> - "$OPTIND" : " $OPTARG; fi
   case $option in
      b) # CREDITOR name / company title
         CRED_NAME=$OPTARG
	 let MANDATORY++
         ;;
      I) # IBAN
         if [[ -z $OPTARG ]]; then echo " -- NO IBAN SPECIFIED -- cannot proceed"; exit 2; else CRED_IBAN=$OPTARG; fi
	 let MANDATORY++
         ;;
      a) # CREDITOR street address
         CRED_ADDRA=$OPTARG
	 let MANDATORY++
         ;;
      n) # CREDITOR building address number
         CRED_ADDRN=$OPTARG
	 let MANDATORY++
         ;;
      p) # CREDITOR postcode
	 CRED_ZIP=$OPTARG
	 let MANDATORY++
         ;;
      t) # CREDITOR town
	 CRED_TOWN=$OPTARG
	 let MANDATORY++
         ;;
      c) # CREDITOR country (default 756)
	 CRED_COUNTRY=$OPTARG
	 let MANDATORY++
         ;;
      C) # CREDITOR currency (default 756)
	 CRED_CURR=$OPTARG
	 let MANDATORY++
         ;;
      D) # DEBITOR name / company title
         DEB_NAME=$OPTARG
         ;;
      A) # DEBITOR street address
         DEB_ADDRA=$OPTARG
         ;;
      N) # DEBITOR building address number
         DEB_ADDRN=$OPTARG
         ;;
      P) # DEBITOR postcode
         DEB_ZIP=$OPTARG
         ;;
      T) # DEBITOR town
         DEB_TOWN=$OPTARG
         ;;
      x) # debitor currency
         DEB_CURR=$OPTARG
	 #let MANDATORY++
         ;;
      X) # debitor country
         DEB_COUNTRY=$OPTARG
	 #let MANDATORY++
         ;;
      M) # amount (or 0 if no amount)
         if [[ -z $OPTARG ]]; then echo " -- NO AMOUNT SPECIFIED -- proceeding without amount"; else DEB_AMT=$OPTARG; fi
         ;;
      R) # REF number
         DEB_REF=$OPTARG
	 if [[ $(echo -n $DEB_REF | wc -c) != "26" ]]; then echo "-- Reference must be 26 digits"; exit 127; fi
         ;;
      G) # REF message
	 if [[ -n $OPTARG ]]; then DEB_MSG=$(echo $OPTARG | tr ' 	' '+' | sed -e ':a;N;$!ba;s/\n//g' | sed -e ':a;N;$!ba;s/\r//g' | sed 's/++/+/g' | sed 's/-$//'); fi
         ;;
      d) # dirname
	 if [[ -s $OPTARG ]]; then DIRNAME=$OPTARG ; fi
	 if $(ls -1d $OPTARG >/dev/null 2>&1); then continue; else echo " --- directory does not exist" && exit 2; fi
	 let MANDATORY++
         ;;
      f) # filename
	 FNAME=$OPTARG
	 let MANDATORY++
         ;;
      v) echo " --- VERBOSE MODE ON"
         VERBOSE_BVR=1
	 ;;
      h) usage
	 shift
	 break
	 ;;
      *) echo "Error: Invalid option"
	 usage
	 echo -e " --- erratic option "$option" - index "$OPTIND" : " $OPTARG
	 shift
	 break
	 ;;
   esac
done
shift "$((OPTIND-1))"

if [[ $MANDATORY -lt 9 ]]; then echo " --- script did not receive enough mandatory options (parsed: $MANDATORY/10)"; exit 2; fi

if [[ -z $DIRNAME ]]; then DIRNAME=$(dirname $(basename $0)); fi
BASE=$DIRNAME
COOKIE=${DIRNAME}/"my-cookie"

CRED_NAME=$(purify $(echo "$CRED_NAME"))
CRED_ADDR=$(echo "$CRED_ADDR" | tr ' ' '+')
#htmlEscape() 
CRED_ADDRA=$(echo "$CRED_ADDRA" | tr ' ' '+')
CRED_ADDRA=$(purify $(echo "$CRED_ADDRA"))
CRED_TOWN=$(echo "$CRED_TOWN" | tr ' ' '+')

DEB_NAME=$(purify $(echo "$DEB_NAME"))
DEB_ADDR=$(echo "$DEB_ADDR" | tr ' ' '+')
DEB_ADDRA=$(echo "$DEB_ADDRA" | tr ' ' '+')
DEB_TOWN=$(echo "$DEB_TOWN" | tr ' ' '+')
#DEB_ADDRN=$(echo $DEB_ADDR | awk -F ',' '{print $1}')

#if [ -s $DEB_AMT ]; then true; else DEB_AMT=$(echo "$6" | tr -d \'); fi
if [[ -z $DEB_AMT || $DEB_AMT -lt 0,02 ]]; then
  DEB_AMT=''
  echo "DEB_AMT_CRC to script: ZERO AMOUNT INVOICE" | tee -a $BASE/amt.txt 
else
  # Leading 010 - mandatory prefix to 9 more digits and control digit (total 13 and field-sep-char '>' in old BVR)
  DEB_AMT_CRC=$(printf "01%010d" $DEB_AMT)
  #DEB_AMT_CRC=$(perl -e "printf('01%0.2d\n', $DEB_AMT)")
  #echo "DEB_AMT_CRC perl: " $DEB_AMT_CRC >> $BASE/amt.txt
  DEB_AMT_TMP=$(echo $DEB_AMT | tr ',' '.' )
  DEB_AMT_CRC=$(perl -e "printf('010%010.2f', $DEB_AMT_TMP)" | tr -d ',.\n')
  echo "DEB_AMT: " $DEB_AMT >> $BASE/amt.txt
  echo "DEB_AMT_CRC : "$DEB_AMT_CRC | tee -a $BASE/amt.txt
  MOD10_M=$(`dirname $(basename $0)`/mod10-rec-universal.py -i $DEB_AMT_CRC -o $BASE/crc_amt_orig.csv 2>&1 | head -1)
  MON_REF_9=$MOD10_M
fi

if [[ -n $DEB_REF ]]; then 
  MOD10_R=$(`dirname $(basename $0)`/mod10-rec-universal.py -i $DEB_REF -o $BASE/crc_ref_orig.csv 2>&1 | head -1)
  DEB_REF_27=$MOD10_R
  echo "DEB_REF_27  : "$DEB_REF_27 | tee -a $BASE/amt.txt
  echo "DEB_REF     : "$DEB_REF
fi

if [[ $DEB_CURR = 756 ]]; then
  true
else
  if [[ $DEB_CURR == "EUR" || $DEB_CURR == 'eur' ]]; then DEB_CURR=978; fi # EUR 978, CHF 756
  if [[ $DEB_CURR == "CHF" || $DEB_CURR == 'chf' ]]; then DEB_CURR=756; fi # EUR 978, CHF 756
  echo "UNKNOWN DEBTOR CURRENCY. ($7, $@)"
  exit 2
fi

#if [[ $DEB_COUNTRY = 756 ]]; then true; else
#  if [[ $DEB_COUNTRY == "CH" || $DEB_COUNTRY == 'ch' ]]; then
#    DEB_COUNTRY=756 # FR 250, CH 756, IT 380
#  else
#    if [[ $DEB_COUNTRY == "FR" || $DEB_COUNTRY == 'fr' ]]; then
#      DEB_COUNTRY=250 # FR 250, CH 756, IT 380
#    else
#      if [[ $DEB_COUNTRY == "IT" || $DEB_COUNTRY == 'it' ]]; then
#        DEB_COUNTRY=380 # FR 250, CH 756, IT 380
#      else
#        echo "UNKNOWN COUNTRY. PAYS PAS CONNU."
#        exit 2
#      fi
#    fi
#  fi
#fi

DEB_MSG+=$(echo "+"$DEB_REF_27"-"$MON_REF | tr ' ' '+' | sed -e ':a;N;$!ba;s/\n//g' | sed -e ':a;N;$!ba;s/\r//g' | sed 's/++/+/g' | sed 's/-$//' )

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

###DEB_NAME=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n' | awk -F '##' '{print $2}' | tr -d '\n\r' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/^+//' | sed 's/+$//')
###DEB_ADDR=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $3}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//')
###DEB_ADDRA=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $3}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | awk -F ',' '{print $2}' | cut -c  1-)
####DEB_ADDRN=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')\r\n"' | awk -F '##' '{print $4}' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | awk -F ',' '{print $2}' | cut -c  1-)
###DEB_ZIP=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')' | awk -F '##' '{print $4}' | tr -d '[:alpha:]' | tr -d ' \r\n')
###DEB_TOWN=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | tr -d ')' | awk -F '##' '{print $5}' | sed 's/^ //' | tr ' ' '+' | perl -pe 's[\\(?:([0-7]{1,3})|(.))] [defined($1) ? chr(oct($1)) : $2]eg' | iconv -f ISO-8859-1 -t UTF-8 | sed 's/+$//' | sed 's/+$//')
###DEB_AMT=$(grep -a '/Auth' $BASE/eeee.pdf | awk -F '(' '{print $2}' | awk -F '##' '{print $6}' | tr -d '[:alpha:]' | tr -d ' \r\n')

if [[ $VERBOSE_BVR -eq 1 ]]; then echo "
-------------------------------
START @ `date +%s`
-------------------------------
C.name : $CRED_NAME
C.iban : $CRED_IBAN
C.addr : $CRED_ADDR
C.addra: $CRED_ADDRA
C.addrn: $CRED_ADDRN
C.postc: $CRED_ZIP
C.town : $CRED_TOWN
C.state: $CRED_CURR
C.state: $CRED_COUNTRY
-------------------------------
D.name	: $DEB_NAME
D.addr	: $DEB_ADDR
D.addra	: $DEB_ADDRA
D.addra	: $DEB_ADDRA
D.addrn	: $DEB_ADDRN
D.postc	: $DEB_ZIP
D.town	: $DEB_TOWN
-------------------------------
D.amt	: $DEB_AMT
D.amtc	: $DEB_AMT_CRC
D.amt	: $MON_REF_9
D.curr	: $DEB_CURR
D.currc	: $DEB_COUNTRY
-------------------------------
D.ref	: $DEB_REF
D.ref	: $DEB_REF_27
D.msg   : $DEB_MSG
-------------------------------
FNAME	: $FNAME
DIRNAME	: $DIRNAME
CURRENT : $(pwd)
-------------------------------
" | tee -a $BASE/amt.txt
fi

FNAME=$(echo $FNAME | tr -d '/ 	')
if [[ -n $FNAME ]]; then OUTNAME=$BASE/$FNAME; else echo " --- Missing filename !! - using $BASE/facture.pdf" >&2 | tee -a $BASE/amt.txt; OUTNAME=$BASE/facture.pdf; fi

## PRE-GET
curl -s -L -c $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html' > $BASE/log.curl.fetch

SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.fetch | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.fetch | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
if [[ $VERBOSE_BVR -eq 1 ]]; then echo -e " --- step1: \n$SP - $FP"; fi
	
## CREDITOR
curl -s -c $COOKIE -b $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
-H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'qrBillInformation.creditorInformation.name='$CRED_NAME'&qrBillInformation.creditorInformation.iban='$CRED_IBAN'&qrBillInformation.creditorInformation.street='$CRED_ADDRA'&qrBillInformation.creditorInformation.houseNumber='$CRED_ADDRN'&qrBillInformation.creditorInformation.zipCode='$CRED_ZIP'&qrBillInformation.creditorInformation.city='$CRED_TOWN'&qrBillInformation.creditorInformation.country='$CRED_COUNTRY'&nextPaymentInformation=&_sourcePage='$SP'&__fp='$FP 2>$BASE/log.curl.creditor.error >$BASE/log.curl.creditor

SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.creditor | awk -F 'value' '{print $2}' | cut -c 2- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.creditor | awk -F 'value' '{print $2}' | cut -c 2- | tr -d '<>"' | sed 's/=/%3D/g')
if [[ $VERBOSE_BVR -eq 1 ]]; then echo -e " --- step2: \n$SP - $FP"; fi

## CALCULATE DEB_REF CRC when amount is present - otherwise just proceed preparing the payment template
curl -s -b $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do?calculateQrReference=&qrReference='$DEB_REF \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
-H 'Accept: */*' \
-H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'X-Requested-With: XMLHttpRequest' \
-H 'Connection: keep-alive' 2> $BASE/log.curl.crcref.error | tee $BASE/log.curl.crcref | sed -n 's/{ "qrReference" : "\(.*\)" }/\1/p' | tr -d ' ' | tail -1 > $BASE/crc.final

# old regex / other API: grep -A 1 'div id="calculatedQrReference"' | tail -1 > $BASE/crc.final

## PAYMENT  METADATA
curl -Ss -b $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
    -H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
    -H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://www.postfinance.ch' \
    -H 'Connection: keep-alive' \
    -H 'Upgrade-Insecure-Requests: 1' \
    --data-raw 'qrBillInformation.paymentInformation.amount='$DEB_AMT'&qrBillInformation.paymentInformation.currency='$DEB_CURR'&qrBillInformation.paymentInformation.qrReference='$DEB_REF_27'&qrBillInformation.paymentInformation.message='$DEB_MSG'&nextDebtorInformation=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.amount
    
    SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.amount | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
    FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.amount | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
    if [[ $VERBOSE_BVR -eq 1 ]]; then echo -e " --- step3: \n$SP - $FP"; fi

if [[ -n $DEB_NAME ]]; then
    DEB_INPUT=1
else
    DEB_INPUT=0
    DEB_NAME=''
    DEB_ADDRA=''
    DEB_ADDRN=''
    DEB_ZIP=''
    DEB_TOWN=''
    DEB_COUNTRY=756
fi

## DEBTOR
curl -s -b $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
-H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'qrBillInformation.debtorInformation.addInformation='$DEB_INPUT'&qrBillInformation.debtorInformation.name='$DEB_NAME'&qrBillInformation.debtorInformation.street='$DEB_ADDRA'&qrBillInformation.debtorInformation.houseNumber='$DEB_ADDRN'&qrBillInformation.debtorInformation.zipCode='$DEB_ZIP'&qrBillInformation.debtorInformation.city='$DEB_TOWN'&qrBillInformation.debtorInformation.country='$DEB_COUNTRY'&nextSummary=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.debtor
SP=$(grep '<input type="hidden" name="_sourcePage" value="' $BASE/log.curl.debtor | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')
FP=$(grep '<input type="hidden" name="__fp" value="' $BASE/log.curl.debtor | awk -F 'value' '{print "aa"$2}' | cut -c 4- | tr -d '<>"' | sed 's/=/%3D/g')

if [[ $VERBOSE_BVR -eq 1 ]]; then echo -e " --- step4: \n$SP - $FP"; fi

## FINALIZE
curl -s -b $COOKIE 'https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:81.0) Gecko/20100101 Firefox/81.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3' \
-H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-H 'Origin: https://www.postfinance.ch' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' \
--data-raw 'nextQrBillCreated=&_sourcePage='$SP'&__fp='$FP 2>&1 >$BASE/log.curl.finalize

TS=$(grep '<input id="downloadUrl" type="hidden" value="/pfch/web/qrbill/Index.do?createQrBill' $BASE/log.curl.finalize | awk -F 'time' '{print $2}' | tr -d '=' | awk -F '"' '{print $1}')
echo $TS

## DOWNLOAD
curl -s -b $COOKIE 'https://www.postfinance.ch/pfch/web/qrbill/Index.do?createQrBill&time='$TS \
-H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:79.0) Gecko/20100101 Firefox/79.0' \
-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
-H 'Accept-Language: en-US,en;q=0.5' \
-o $OUTNAME \
-H 'Referer: https://www.postfinance.ch/fr/assistance/services/outils-calculateurs/qr-generator.html/qrbill/Index.do' \
-H 'Connection: keep-alive' \
-H 'Upgrade-Insecure-Requests: 1' 2>$BASE/log.curl.download.error

if [[ $? -eq 0 ]]; then SUCCESS="true"; else SUCCESS="false"; fi

if [[ $VERBOSE_BVR -eq 1 ]]; then echo -e " --- step5: \n$SP - $FP - $TS"; fi
if [[ $SUCCESS == "true" && ! -s $BASE/log.curl.download.error ]]; then
    echo " --- downoad complete" >&2 | tee -a $BASE/amt.txt >> $BASE/run.csv
else
    echo " --- download failed with parameters: $@" >&2 | tee -a $BASE/amt.txt >> $BASE/run.csv
fi

echo -n $MOD10_R | tee $BASE/crc_ref.csv > $BASE/crc_ref.html
echo -n $MOD10_M | tee $BASE/crc_amt.csv > $BASE/crc_amt.html

if [[ $VERBOSE_BVR -eq 1 ]]; then 
  echo -e -n "
-------------------------------
END @ $(date +%s)
-------------------------------
BILLING SUCCESSFUL CREDITOR: $CRED_NAME - $CRED_CURR - $CRED_COUNTRY - $CRED_IBAN
BILLING SUCCESSFUL DEBITOR : $DEB_NAME - $DEB_AMT - $DEB_CURR - $DEB_COUNTRY - $DEB_REF_27
DOWNLOAD SUCCESSFUL
-------------------------------
" | tee -a $BASE/amt.txt >> $BASE/run.csv
else
  if [[ $SUCCESS == "false" && -s $BASE/log.curl.download.error ]]; then
    echo " --- downoad failed"
    exit 2
  else
    echo " --- data error, issues in generating or downloading QR";
    exit 1
  fi
fi

SUCCESS=false

if [[ LINUX = 1 ]]; then
  # vector and EncapsulatePS generation
  pdftocairo -f 1 -l 1 -eps $OUTNAME - | sed '/^BT$/,/^ET$/ d' > $OUTNAME.eps
  pdftocairo -scale-to 1024 -tiff $OUTNAME $OUTNAME.tiff
  pdftocairo -duplex -paper A3 -expand -svg $OUTNAME $OUTNAME.svg
  pdftoppm -mono $OUTNAME $OUTNAME.ppm
  pdfimages -all $OUTNAME $BASE

  # just to verify visually
  xdg-open $OUTNAME &
  wait $!; xdg-open $OUTNAME.eps &
  wait $!; xdg-open $OUTNAME.tiff-1.tif &
  wait $!; xdg-open $OUTNAME.svg &
  wait $!; xdg-open $OUTNAME.ppm-1.pbm &
  wait $!; xdg-open $BASE/-000.jpg &
fi

exit 0

