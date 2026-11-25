"""Normalize and validate Swiss QR-bill inputs before sending them."""

import re
import unicodedata
from typing import Optional


class InputError(ValueError):
    """A field is missing or cannot be represented in a Swiss QR-bill."""


# SIX QR-bill implementation guidelines v2.4, section 4.1.1.
QR_TEXT = re.compile(r"[\x20-\x7E\u00A0-\u017F\u0218-\u021B\u20AC]*")
TYPOGRAPHIC_PUNCTUATION = str.maketrans({
    **dict.fromkeys("‘’‚‛ʼ′", "'"),
    **dict.fromkeys('“”„‟″', '"'),
    **dict.fromkeys("‐‑‒–—―−", "-"),
    **dict.fromkeys("\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F", " "),
    "…": "...",
})
CURRENCIES = {"CHF": "CHF", "756": "CHF", "EUR": "EUR", "978": "EUR"}
MOD10_TABLE = (0, 9, 4, 6, 8, 2, 7, 1, 3, 5)


def normalize_text(value: Optional[str], label: str, limit: int, *, required: bool = False) -> str:
    text = unicodedata.normalize("NFC", (value or "").translate(TYPOGRAPHIC_PUNCTUATION))
    text = text.strip(" \u00A0")
    if not QR_TEXT.fullmatch(text):
        raise InputError(f"{label} contains a character outside the Swiss QR-bill character set.")
    if required and not text:
        raise InputError(f"{label} is required.")
    if len(text) > limit:
        raise InputError(f"{label} must be at most {limit} characters.")
    return text


def compact_identifier(value: Optional[str]) -> str:
    return re.sub(r"[ \u00A0\u202F]", "", value or "")


def valid_mod97(identifier: str) -> bool:
    rearranged = identifier[4:] + identifier[:4]
    digits = "".join(char if char.isdigit() else str(ord(char) - 55) for char in rearranged)
    return 2 <= int(identifier[2:4]) <= 98 and int(digits) % 97 == 1


def normalize_iban(value: Optional[str]) -> str:
    iban = compact_identifier(value)
    if not re.fullmatch(r"(?:CH|LI)[0-9]{7}[A-Z0-9]{12}", iban, flags=re.ASCII | re.IGNORECASE):
        raise InputError("Creditor IBAN must be a 21-character Swiss or Liechtenstein IBAN.")
    iban = iban.upper()
    if not valid_mod97(iban):
        raise InputError("Creditor IBAN has an invalid check digit.")
    return iban


def normalize_amount(value: Optional[str]) -> Optional[str]:
    amount = (value or "").strip(" \u00A0")
    if not amount:
        return None
    if not re.fullmatch(r"[0-9]+(?:[.,][0-9]{1,2})?", amount):
        raise InputError("Amount must be a positive number with at most two decimal places, or blank.")
    whole, _, fraction = amount.replace(",", ".").partition(".")
    whole = whole.lstrip("0") or "0"
    fraction = fraction.ljust(2, "0")
    if len(whole) > 9:
        raise InputError("Amount must be at most 999999999.99.")
    if whole == "0" and fraction == "00":  # Legacy spelling for an open amount.
        return None
    return f"{whole}.{fraction}"


def normalize_currency(value: str) -> str:
    currency = CURRENCIES.get(value.strip(" ").upper())
    if currency is None:
        raise InputError("Currency must be CHF or EUR.")
    return currency


def check_digit(digits: str) -> int:
    if not re.fullmatch(r"[0-9]+", digits):
        raise InputError("A Modulo 10 reference must contain only ASCII digits.")
    carry = 0
    for digit in digits:
        carry = MOD10_TABLE[(carry + int(digit)) % 10]
    return (10 - carry) % 10


def normalize_reference(value: Optional[str], iban: str, currency: str) -> Optional[str]:
    reference = compact_identifier(value)
    if 30000 <= int(iban[4:9]) <= 31999:
        if currency != "CHF":
            raise InputError("QR-IBANs can only be used for CHF QR-bills.")
        if not re.fullmatch(r"[0-9]{26,27}", reference):
            raise InputError("A QR-IBAN requires a 26- or 27-digit QR reference.")
        digit = str(check_digit(reference[:26]))
        if len(reference) == 26:
            reference += digit
        if reference[26] != digit or reference == "0" * 27:
            raise InputError("QR reference must be nonzero and have a valid check digit.")
        return reference

    if not reference:
        return None
    if not re.fullmatch(r"RF[0-9]{2}[A-Z0-9]{1,21}", reference, flags=re.ASCII | re.IGNORECASE):
        raise InputError("A standard IBAN accepts an RF creditor reference or no reference.")
    reference = reference.upper()
    if not valid_mod97(reference):
        raise InputError("RF creditor reference has an invalid check digit.")
    return reference
