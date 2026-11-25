# QR-Rechnung

Create a Swiss QR-bill PDF with the [PostFinance QR generator](https://www.postfinance.ch/en/business/products/invoices/qr-bill/qr-generator.html#/).
The two entry points, `./curl.sh` and `./curl-rest.sh`, use Python 3.9 or later and its standard library. Keep the launchers and both Python modules together when installing them for FileMaker.

## Example

The IBAN and reference below are examples from SIX. Use the following command with your own validated payment details when generating a bill.

```sh
./curl.sh \
  -I 'CH4431999123000889012' \
  -b "Épreuves d’été & Fils" -a 'Rue de l’École' -n 12 \
  -p 1201 -t Genève -C CH -c CHF \
  -M '50,00' -R '00000820779122585742128669' \
  -G 'Brochures + épreuves, édition 2' \
  -d './PDF output' -f 'Facture été.pdf'
```

Create the output directory before running the command. Run `./curl.sh --help` for all options.

- Omit `-M` for an open amount. The legacy value `0` also leaves the amount open.
- Omit the debtor options to leave the recipient blank. A named debtor requires a name, postal code, and town. Use `--creditor-po-box` or `--debtor-po-box` for a P.O. box and omit the corresponding street and house number.
- A CHF QR-IBAN requires a QR reference. Pass 26 digits to calculate its check digit, or pass all 27 digits to validate it. With a standard IBAN use `-G` for the payment message. The PostFinance form exposes its reference field for QR-IBANs.
- The original short options and numeric codes such as `756` and `978` still work. The client also recognizes common country abbreviations and the original `curl.sh` country/currency ordering when it can distinguish the values. See `countries.dat` for other country codes.

## Text and output

Text is normalized to UTF-8 NFC. Supported accents, ligatures, apostrophes, ampersands, and plus signs are preserved. Curly quotes, typographic dashes, and spacing outside the SIX repertoire are converted to their supported equivalents. For other unsupported characters the command reports which field needs attention. See [SIX QR-bill guidelines, §4.1.1](https://www.six-group.com/dam/download/banking-services/standardization/qr-bill/ig-qr-bill-v2.4-en.pdf#page=30).

The client sends the supplied invoice and address details to PostFinance. Each invocation uses its own session. On success it saves the PDF and the existing `crc_ref.csv`, `crc_ref.html`, `crc_amt.csv`, and `crc_amt.html` checksum files for FileMaker. Check the exit status before reading them. Use separate output directories for overlapping runs because the checksum filenames are shared within each directory.

## Offline verification

```sh
python3 -B -m unittest -v
```

The tests use synthetic data and mock the PostFinance requests.
