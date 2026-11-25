"""Command-line client for the PostFinance QR-bill generator."""

from __future__ import annotations

import argparse
from decimal import Decimal
from http.cookiejar import CookieJar
import json
import os
from pathlib import Path
import re
import sys
from tempfile import TemporaryDirectory
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urlsplit
from urllib.request import (
    HTTPCookieProcessor,
    HTTPRedirectHandler,
    Request,
    build_opener,
)

from qrbill_input import (
    InputError,
    check_digit,
    compact_identifier,
    normalize_amount,
    normalize_currency,
    normalize_iban,
    normalize_reference,
    normalize_text,
)


ORIGIN = "https://www.postfinance.ch"
GENERATOR = "/en/business/products/invoices/qr-bill/qr-generator.html"
API_BASE = "/pfch/rest/api/qrbill"
COUNTRY_NUMBERS = {
    "AT": "40", "BE": "56", "CH": "756", "CZ": "203", "DE": "276",
    "ES": "724", "FR": "250", "GB": "826", "IT": "380", "LI": "438",
    "LU": "442", "NL": "528", "PL": "616", "PT": "620", "US": "840",
}
CURRENCY_CODES = {"CHF": "756", "EUR": "978"}
SIDECARS = ("crc_ref.csv", "crc_ref.html", "crc_amt.csv", "crc_amt.html")


class GeneratorError(RuntimeError):
    """A PostFinance request failed or returned an unusable result."""


class ArgumentParser(argparse.ArgumentParser):
    def error(self, message):
        if message.startswith("unrecognized arguments:"):
            message = "unexpected argument; quote values and paths containing spaces"
        super().error(message)


def parse_args(argv):
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("-I", "--iban", required=True, help="creditor IBAN or QR-IBAN")
    parser.add_argument("-b", "--creditor-name", required=True)
    parser.add_argument("-a", "--creditor-street", default="")
    parser.add_argument("-n", "--creditor-house-number", default="")
    parser.add_argument("--creditor-po-box", action="store_true", help="creditor uses a P.O. box")
    parser.add_argument("-p", "--creditor-postcode", required=True)
    parser.add_argument("-t", "--creditor-town", required=True)
    parser.add_argument("-C", "--creditor-country", help="country code (default CH)")
    parser.add_argument("-c", "--currency", help="CHF or EUR (default CHF)")
    parser.add_argument("-D", "--debtor-name", default="")
    parser.add_argument("-A", "--debtor-street", default="")
    parser.add_argument("-N", "--debtor-house-number", default="")
    parser.add_argument("--debtor-po-box", action="store_true", help="debtor uses a P.O. box")
    parser.add_argument("-P", "--debtor-postcode", default="")
    parser.add_argument("-T", "--debtor-town", default="")
    parser.add_argument("-X", "--debtor-country", help="country code (default CH)")
    parser.add_argument("-x", "--debtor-currency", help="legacy alias for the invoice currency")
    parser.add_argument("-M", "--amount", help="omit, leave blank or pass zero for an open amount")
    parser.add_argument("-R", "--reference", help="26- or 27-digit QR reference for a QR-IBAN")
    parser.add_argument("-G", "--message", default="", help="additional information")
    parser.add_argument("-d", "--directory", type=Path, default=Path("."))
    parser.add_argument("-f", "-F", "--filename", required=True, help="output PDF filename")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser.parse_args(argv)


def country_number(value):
    country = (value or "CH").strip().upper()
    if country in COUNTRY_NUMBERS:
        return COUNTRY_NUMBERS[country]
    if re.fullmatch(r"[0-9]{1,3}", country) and int(country) > 0 and country != "978":
        return str(int(country))
    raise InputError("Country: use a supported country abbreviation or its ISO numeric code.")


def address(name, street, house_number, zip_code, town, country, role, *, po_box):
    street = normalize_text(street, f"{role} street", 70)
    house_number = normalize_text(house_number, f"{role} house number", 16)
    if po_box and (street or house_number):
        raise InputError(f"{role}: omit street and house number when selecting P.O. box.")
    return {
        "name": normalize_text(name, f"{role} name", 70, required=True),
        "street": street or None,
        "houseNumber": house_number or None,
        "zipCode": normalize_text(zip_code, f"{role} postal code", 16, required=True),
        "city": normalize_text(town, f"{role} town", 35, required=True),
        "country": country_number(country),
        "postOfficeBox": "1" if po_box else "0",
    }


def bill_payload(args):
    currency_value = args.currency
    creditor_country = args.creditor_country
    currency_inputs = {*CURRENCY_CODES, *CURRENCY_CODES.values()}
    country_option = (creditor_country or "").strip().upper()
    currency_option = (currency_value or "").strip().upper()
    if (
        (currency_option and currency_option not in currency_inputs
         and (country_option or "CHF") in currency_inputs)
        or (currency_option == "756" and country_option in {"CHF", "EUR", "978"})
    ):
        # The original curl.sh assigned -c to country and -C to currency.
        currency_value, creditor_country = creditor_country, currency_value
    currency = normalize_currency(currency_value or args.debtor_currency or "CHF")
    if args.debtor_currency and normalize_currency(args.debtor_currency) != currency:
        raise InputError("The invoice accepts one currency. Use the same currency for -c and -x.")

    iban = normalize_iban(args.iban)
    creditor = address(
        args.creditor_name, args.creditor_street, args.creditor_house_number,
        args.creditor_postcode, args.creditor_town, creditor_country, "Creditor",
        po_box=args.creditor_po_box,
    )
    creditor["iban"] = iban

    debtor_values = (
        args.debtor_name, args.debtor_street, args.debtor_house_number,
        args.debtor_postcode, args.debtor_town,
    )
    if args.debtor_po_box or any(value.strip() for value in debtor_values):
        debtor = address(*debtor_values, args.debtor_country, "Debtor", po_box=args.debtor_po_box)
        debtor["addInformation"] = "1"
    else:
        debtor = {
            "addInformation": "0", "name": None, "street": None,
            "houseNumber": None, "zipCode": None, "city": None,
            "country": country_number(args.debtor_country), "postOfficeBox": "0",
        }

    reference = normalize_reference(args.reference, iban, currency)
    if reference and reference.startswith("RF"):
        raise InputError("The PostFinance generator offers no RF reference field for a standard IBAN.")

    return {
        "creditor": creditor,
        "paymentInformation": {
            "amount": normalize_amount(args.amount),
            "currency": CURRENCY_CODES[currency],
            "message": normalize_text(args.message, "Additional information", 140) or None,
            "qrReference": reference,
        },
        "debtor": debtor,
        "step": {"stepName": "pdf", "stepIndex": 4},
    }


class PostFinanceRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        target = urlsplit(newurl)
        if (target.scheme, target.netloc) != ("https", "www.postfinance.ch"):
            raise GeneratorError("PostFinance redirected the request outside its generator.")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


class PostFinance:
    def __init__(self):
        self.opener = build_opener(HTTPCookieProcessor(CookieJar()), PostFinanceRedirects())

    def __call__(self, path, payload=None):
        headers = {
            "Accept": "application/json, application/pdf",
            "Referer": ORIGIN + GENERATOR,
        }
        body = None
        if payload is not None:
            headers["Content-Type"] = "application/json; charset=utf-8"
            headers["Origin"] = ORIGIN
            body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        request = Request(ORIGIN + path, data=body, headers=headers)

        try:
            with self.opener.open(request, timeout=30) as response:
                return response.headers.get_content_type(), response.read()
        except HTTPError as error:
            raise GeneratorError(f"PostFinance returned HTTP {error.code}.") from error
        except (URLError, TimeoutError) as error:
            raise GeneratorError("Could not reach the PostFinance QR-bill generator.") from error


def result_object(response, step):
    content_type, body = response
    if content_type != "application/json" and not content_type.endswith("+json"):
        raise GeneratorError("PostFinance returned an unexpected response instead of JSON.")
    try:
        envelope = json.loads(body)
    except (UnicodeError, json.JSONDecodeError) as error:
        raise GeneratorError("PostFinance returned invalid JSON.") from error

    if not isinstance(envelope, dict) or envelope.get("errors") or envelope.get("validationFieldErrors"):
        raise GeneratorError(f"PostFinance could not complete {step}.")
    result = envelope.get("result")
    if (
        not isinstance(result, dict) or result.get("errors")
        or result.get("validationFieldErrors") or result.get("valid") is False
    ):
        raise GeneratorError(f"PostFinance could not complete {step}.")
    return result


def is_pdf(body):
    return body.startswith(b"%PDF-") and body[-1024:].rstrip().endswith(b"%%EOF")


def generate_pdf(payload, requester):
    state = result_object(requester(f"{API_BASE}/data"), "initialization")
    payment = payload["paymentInformation"]
    reference = payment["qrReference"]
    for section in ("creditor", "paymentInformation", "debtor"):
        if not isinstance(state.get(section), dict):
            raise GeneratorError(f"PostFinance did not return its {section} fields.")
        form = {**state[section], **payload[section]}
        if section == "paymentInformation" and reference:
            # The editable reference is the base number. The validated state
            # separately carries the reference with its check digit.
            form["qrReference"] = reference[:-1]
        state = result_object(requester(f"{API_BASE}/writeAndValidate/{section}", form), section)

    validated = state.get("paymentInformation")
    if not isinstance(validated, dict):
        raise GeneratorError("PostFinance did not return validated payment details.")
    validated_reference = validated.get("qrReference") or ""
    amount = validated.get("amount")
    try:
        validated_amount = normalize_amount(str(amount)) if amount is not None else None
    except InputError as error:
        raise GeneratorError("PostFinance returned an invalid payment amount.") from error
    if (
        not isinstance(validated_reference, str)
        or compact_identifier(validated_reference) != (reference or "")
        or str(validated.get("currency")) != payment["currency"]
        or validated_amount != payment["amount"]
    ):
        raise GeneratorError("The validated amount, currency, or reference differs from the request.")

    final_state = {**state, "step": payload["step"]}
    result = result_object(requester(f"{API_BASE}/createQrBill", final_state), "PDF generation")
    download_url = result.get("downloadUrl")
    if not isinstance(download_url, str) or not download_url:
        raise GeneratorError("PostFinance did not return a QR-bill download URL.")
    try:
        download = urlsplit(urljoin(ORIGIN + "/", download_url))
    except ValueError as error:
        raise GeneratorError("PostFinance returned an invalid download URL.") from error
    if (download.scheme, download.netloc) != ("https", "www.postfinance.ch"):
        raise GeneratorError("PostFinance returned a download URL outside its own site.")

    path = download.path
    if download.query:
        path += "?" + download.query
    _, pdf = requester(path)
    if not is_pdf(pdf):
        raise GeneratorError("PostFinance did not return a complete PDF.")
    return pdf


def output_path(args):
    filename = args.filename
    if (
        not filename.strip() or filename in {".", ".."} or "/" in filename or "\\" in filename
        or filename.lower() in SIDECARS or any(ord(char) < 32 for char in filename)
    ):
        raise InputError("Output filename: supply a filename only, and use -d for its directory.")
    if not args.directory.is_dir():
        raise InputError("Output directory does not exist.")
    return args.directory / filename


def save_outputs(path, pdf, payment):
    reference = payment["qrReference"] or ""
    amount = payment["amount"]
    amount_reference = ""
    if amount:
        cents = int(Decimal(amount) * 100)
        prefix = f"010{cents:09d}"
        amount_reference = f"{prefix}{check_digit(prefix)}"

    sidecars = {
        filename: reference if filename.startswith("crc_ref") else amount_reference
        for filename in SIDECARS
    }
    with TemporaryDirectory(prefix=".qrbill-", dir=path.parent) as staging:
        staging_path = Path(staging)
        for filename, value in sidecars.items():
            (staging_path / filename).write_text(value, encoding="ascii")
        (staging_path / path.name).write_bytes(pdf)

        for filename in sidecars:
            os.replace(staging_path / filename, path.parent / filename)
        os.replace(staging_path / path.name, path)


def main(argv=None):
    args = parse_args(argv)
    try:
        path = output_path(args)
        payload = bill_payload(args)
        if args.verbose:
            print("Requesting a QR-bill from PostFinance.", file=sys.stderr)
        pdf = generate_pdf(payload, PostFinance())
        save_outputs(path, pdf, payload["paymentInformation"])
        if args.verbose:
            print("Saved the QR-bill PDF and FileMaker checksum files.", file=sys.stderr)
    except (InputError, GeneratorError) as error:
        print(f"QR-bill: {error}", file=sys.stderr)
        return 2
    except OSError:
        print("QR-bill: could not write the output files.", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
