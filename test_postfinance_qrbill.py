from contextlib import redirect_stderr
import io
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import MagicMock, Mock, call, patch

from postfinance_qrbill import (
    API_BASE,
    GeneratorError,
    PostFinance,
    bill_payload,
    generate_pdf,
    main,
    parse_args,
)
from qrbill_input import (
    InputError,
    check_digit,
    normalize_amount,
    normalize_currency,
    normalize_iban,
    normalize_reference,
    normalize_text,
)


# Sample identifiers from SIX Swiss QR-bill guidelines v2.4, annexes A and B.
QR_IBAN = "CH4431999123000889012"
STANDARD_IBAN = "CH5800791123000889012"
QR_REFERENCE = "210000000003139471430009017"
QR_REFERENCE_WITH_ZEROS = "000008207791225857421286694"
RF_REFERENCE = "RF18539007547034"
DOWNLOAD_PATH = f"{API_BASE}/downloadQrBill/synthetic-response-token"
PDF_BYTES = b"%PDF-1.4\n% synthetic fixture\n%%EOF\n"
PAYMENT_DEFAULTS = {
    "addAlternativeSchemes": [],
    "alternativeSchemeEBill": None,
    "alternativeSchemeTwint": None,
    "billInformation": None,
}


def sample_options(iban=STANDARD_IBAN, extra=()):
    return [
        "-I", iban, "-b", "E\u0301preuves & Fils", "-a", "Rue de l’Été / Atelier_2",
        "-n", "12+14", "-p", "1201", "-t", "Genève", "-f", "Facture été.pdf",
        *extra,
    ]


def sample_args(iban=STANDARD_IBAN, extra=()):
    return parse_args(sample_options(iban, extra))


def wrapped_response(result):
    return "application/json", json.dumps({"result": result}).encode("utf-8")


def generator_replies(payload, download_path=DOWNLOAD_PATH, pdf_reply=("application/pdf", PDF_BYTES)):
    reference = payload["paymentInformation"]["qrReference"]
    empty_payment = {
        "amount": None, "currency": "756", "message": None, "qrReference": None,
        **PAYMENT_DEFAULTS,
    }
    initial_state = {
        "creditor": {
            **dict.fromkeys(payload["creditor"]), "country": "756", "postOfficeBox": "0",
        },
        "paymentInformation": empty_payment,
        "debtor": {
            **dict.fromkeys(payload["debtor"]), "country": "756", "postOfficeBox": "0",
            "addInformation": "1",
        },
        "downloadUrl": None, "pdfFileName": None, "qrIban": False, "qrReferenceInput": None,
        "step": {"stepName": "creditor", "stepIndex": 0},
    }
    creditor_state = {
        **initial_state, "creditor": payload["creditor"], "qrIban": reference is not None,
        "step": {"stepName": "paymentInformation", "stepIndex": 1},
    }
    payment_state = {
        **creditor_state,
        "paymentInformation": {**empty_payment, **payload["paymentInformation"]},
        "qrReferenceInput": reference[:26] if reference else None,
        "step": {"stepName": "debtor", "stepIndex": 2},
    }
    debtor_state = {
        **payment_state, "debtor": payload["debtor"],
        "step": {"stepName": "summary", "stepIndex": 3},
    }
    created_bill = {**debtor_state, "pdfFileName": "synthetic.pdf", "downloadUrl": download_path}
    return [
        wrapped_response(initial_state), wrapped_response(creditor_state),
        wrapped_response(payment_state), wrapped_response(debtor_state),
        wrapped_response(created_bill),
        pdf_reply,
    ]


class InputTests(unittest.TestCase):
    def test_normalize_mac_accents_and_preserve_allowed_punctuation(self):
        source = '  E\u0301preuves d\'e\u0301te\u0301 & Fils + Œuvres/annexes_2 "vélo" € Șț  '
        expected = 'Épreuves d\'été & Fils + Œuvres/annexes_2 "vélo" € Șț'
        self.assertEqual(normalize_text(source, "Message", 140), expected)

    def test_convert_typographic_punctuation_to_allowed_equivalents(self):
        source = "L’épreuve “bleue” — test… 20\u202f€"
        expected = 'L\'épreuve "bleue" - test... 20 €'
        self.assertEqual(normalize_text(source, "Message", 140), expected)

    def test_reject_text_outside_six_repertoire(self):
        for source in ("édition ☀", "un\ndeux", "un\tdeux", "un\u200bdeux"):
            with self.subTest(source=source), self.assertRaisesRegex(InputError, "Message"):
                normalize_text(source, "Message", 140)

    def test_text_lengths_are_counted_after_normalization(self):
        self.assertEqual(normalize_text("e\u0301" * 140, "Message", 140), "é" * 140)
        with self.assertRaisesRegex(InputError, "140"):
            normalize_text("é" * 139 + "…", "Message", 140)
        with self.assertRaisesRegex(InputError, "Creditor name"):
            normalize_text(" \u00a0 ", "Creditor name", 70, required=True)

    def test_iban_spacing_case_and_checksum(self):
        self.assertEqual(normalize_iban("ch44 3199 9123 0008 8901 2"), QR_IBAN)
        self.assertEqual(normalize_iban("ch58\u202f0079 1123 0008 8901 2"), STANDARD_IBAN)
        with self.assertRaisesRegex(InputError, "check digit"):
            normalize_iban(QR_IBAN[:-1] + "3")

    def test_legacy_numeric_currency_codes(self):
        for code, expected in (("chf", "CHF"), ("756", "CHF"), ("eur", "EUR"), ("978", "EUR")):
            with self.subTest(code=code):
                self.assertEqual(normalize_currency(code), expected)
        with self.assertRaisesRegex(InputError, "Currency"):
            normalize_currency("USD")

    def test_optional_amount_and_exact_decimal_normalization(self):
        examples = {
            None: None,
            "": None,
            "0,00": None,
            "0,01": "0.01",
            "0012,5": "12.50",
            "12": "12.00",
            "999999999,99": "999999999.99",
        }
        for user_input, expected in examples.items():
            with self.subTest(user_input=user_input):
                self.assertEqual(normalize_amount(user_input), expected)

    def test_invalid_or_out_of_range_amounts(self):
        for amount in ("-1", "1.001", "1e2", "12CHF", "١٢", "1000000000.00"):
            with self.subTest(amount=amount), self.assertRaisesRegex(InputError, "Amount"):
                normalize_amount(amount)

    def test_qr_reference_appends_check_digit_and_preserves_leading_zeroes(self):
        self.assertEqual(check_digit(QR_REFERENCE[:-1]), 7)
        self.assertEqual(normalize_reference(QR_REFERENCE[:-1], QR_IBAN, "CHF"), QR_REFERENCE)
        self.assertEqual(
            normalize_reference("00 00082 07791 22585 74212 86694", QR_IBAN, "CHF"),
            QR_REFERENCE_WITH_ZEROS,
        )

    def test_qr_reference_requires_the_right_iban_currency_and_checksum(self):
        for bad_reference in (None, "0" * 27, QR_REFERENCE[:-1] + "8", "９" * 26):
            with self.subTest(bad_reference=bad_reference), self.assertRaises(InputError):
                normalize_reference(bad_reference, QR_IBAN, "CHF")
        with self.assertRaisesRegex(InputError, "CHF"):
            normalize_reference(QR_REFERENCE, QR_IBAN, "EUR")
        with self.assertRaisesRegex(InputError, "standard IBAN"):
            normalize_reference(QR_REFERENCE, STANDARD_IBAN, "CHF")

    def test_standard_iban_allows_optional_scor_reference(self):
        self.assertIsNone(normalize_reference(None, STANDARD_IBAN, "EUR"))
        self.assertEqual(normalize_reference("rf18 5390 0754 7034", STANDARD_IBAN, "EUR"), RF_REFERENCE)
        with self.assertRaisesRegex(InputError, "check digit"):
            normalize_reference("RF19539007547034", STANDARD_IBAN, "EUR")


class PayloadTests(unittest.TestCase):
    def test_structured_addresses_amount_and_qr_reference(self):
        args = sample_args(QR_IBAN, (
            "-c", "CHF", "-C", "756", "-M", "12,05", "-R", QR_REFERENCE[:-1],
            "-D", "Müller & García", "-A", "Rue d’Œuvre", "-N", "3",
            "-P", "01210", "-T", "Ferney-Voltaire", "-X", "FR",
            "-G", 'Épreuves "bleues" + 2 annexes / été',
        ))
        payload = bill_payload(args)

        creditor_fields = {
            "name": "Épreuves & Fils", "iban": QR_IBAN, "street": "Rue de l'Été / Atelier_2",
            "houseNumber": "12+14", "zipCode": "1201", "city": "Genève", "country": "756",
            "postOfficeBox": "0",
        }
        payment_fields = {
            "amount": "12.05", "currency": "756", "qrReference": QR_REFERENCE,
            "message": 'Épreuves "bleues" + 2 annexes / été',
        }
        debtor_fields = {
            "addInformation": "1", "name": "Müller & García", "street": "Rue d'Œuvre",
            "houseNumber": "3", "zipCode": "01210", "city": "Ferney-Voltaire", "country": "250",
            "postOfficeBox": "0",
        }
        self.assertEqual({key: payload["creditor"][key] for key in creditor_fields}, creditor_fields)
        self.assertEqual(
            {key: payload["paymentInformation"][key] for key in payment_fields}, payment_fields,
        )
        self.assertEqual({key: payload["debtor"][key] for key in debtor_fields}, debtor_fields)
        self.assertEqual(args.filename, "Facture été.pdf")

    def test_no_debtor_and_open_amount_use_empty_form_values(self):
        payload = bill_payload(sample_args(extra=("-M", "0", "-X", "756")))
        self.assertIsNone(payload["paymentInformation"]["amount"])
        self.assertIsNone(payload["paymentInformation"]["qrReference"])
        self.assertEqual(payload["paymentInformation"]["currency"], "756")
        self.assertEqual(payload["debtor"]["addInformation"], "0")
        self.assertIsNone(payload["debtor"]["name"])
        self.assertIsNone(payload["debtor"]["zipCode"])

    def test_amount_and_debtor_can_each_be_omitted_independently(self):
        amount_only = bill_payload(sample_args(extra=("-M", "20")))
        self.assertEqual(amount_only["paymentInformation"]["amount"], "20.00")
        self.assertEqual(amount_only["debtor"]["addInformation"], "0")

        debtor_only = bill_payload(sample_args(extra=("-D", "Dupont", "-P", "1201", "-T", "Genève")))
        self.assertIsNone(debtor_only["paymentInformation"]["amount"])
        self.assertEqual(debtor_only["debtor"]["addInformation"], "1")
        self.assertEqual(debtor_only["debtor"]["name"], "Dupont")

    def test_eur_and_historical_country_currency_flags(self):
        # The old curl.sh interpreted -c as country and -C as currency.
        for country, currency, expected in (("LI", "EUR", "438"), ("756", "978", "756")):
            with self.subTest(country=country, currency=currency):
                payload = bill_payload(sample_args(extra=("-c", country, "-C", currency)))
                self.assertEqual(payload["creditor"]["country"], expected)
                self.assertEqual(payload["paymentInformation"]["currency"], "978")
                self.assertIsNone(payload["paymentInformation"]["qrReference"])

    def test_post_office_box_excludes_street_and_house_number(self):
        args = sample_args(extra=(
            "-a", "", "-n", "", "--creditor-po-box",
            "-D", "Dupont & Fils", "-P", "1202", "-T", "Genève", "--debtor-po-box",
        ))
        payload = bill_payload(args)
        for section in ("creditor", "debtor"):
            with self.subTest(section=section):
                self.assertEqual(payload[section]["postOfficeBox"], "1")
                self.assertIsNone(payload[section]["street"])
                self.assertIsNone(payload[section]["houseNumber"])
        with self.assertRaisesRegex(InputError, "P.O. box"):
            bill_payload(sample_args(extra=("--creditor-po-box",)))

    def test_scor_has_no_input_field_in_postfinance_generator(self):
        with self.assertRaises(InputError):
            bill_payload(sample_args(extra=("-R", RF_REFERENCE)))

    def test_mismatched_currencies_and_incomplete_debtor_are_rejected(self):
        with self.assertRaisesRegex(InputError, "one currency"):
            bill_payload(sample_args(extra=("-c", "756", "-x", "978")))
        with self.assertRaisesRegex(InputError, "Debtor postal code"):
            bill_payload(sample_args(extra=("-D", "Dupont & Fils", "-T", "Genève")))


class TransportTests(unittest.TestCase):
    def test_requests_use_validated_state_and_returned_download_url(self):
        payload = bill_payload(sample_args(QR_IBAN, ("-M", "12,05", "-R", QR_REFERENCE)))
        download_url = f"https://www.postfinance.ch{DOWNLOAD_PATH}?download=true"
        requester = Mock(side_effect=generator_replies(payload, download_url))

        self.assertEqual(generate_pdf(payload, requester), PDF_BYTES)

        self.assertEqual(requester.call_args_list[0], call(f"{API_BASE}/data"))
        expected_payment = {
            **PAYMENT_DEFAULTS, **payload["paymentInformation"], "qrReference": QR_REFERENCE[:26],
        }
        self.assertEqual(requester.call_args_list[1:4], [
            call(f"{API_BASE}/writeAndValidate/creditor", payload["creditor"]),
            call(f"{API_BASE}/writeAndValidate/paymentInformation", expected_payment),
            call(f"{API_BASE}/writeAndValidate/debtor", payload["debtor"]),
        ])
        create_path, create_body = requester.call_args_list[4].args
        self.assertEqual(create_path, f"{API_BASE}/createQrBill")
        self.assertEqual(create_body["step"], {"stepName": "pdf", "stepIndex": 4})
        self.assertEqual(create_body["qrReferenceInput"], QR_REFERENCE[:26])
        self.assertEqual(create_body["paymentInformation"]["qrReference"], QR_REFERENCE)
        self.assertEqual(requester.call_args_list[5], call(f"{DOWNLOAD_PATH}?download=true"))

    def test_changed_server_payment_fields_prevent_pdf_creation(self):
        payload = bill_payload(sample_args(QR_IBAN, ("-M", "12.05", "-R", QR_REFERENCE)))
        changes = {"qrReference": QR_REFERENCE_WITH_ZEROS, "amount": "12.06", "currency": "978"}
        for field, changed_value in changes.items():
            with self.subTest(field=field):
                replies = generator_replies(payload)
                for index in (2, 3):
                    state = json.loads(replies[index][1])["result"]
                    state["paymentInformation"][field] = changed_value
                    replies[index] = wrapped_response(state)
                requester = Mock(side_effect=replies)

                with self.assertRaises(GeneratorError):
                    generate_pdf(payload, requester)

                paths = [request.args[0] for request in requester.call_args_list]
                self.assertNotIn(f"{API_BASE}/createQrBill", paths)

    def test_server_field_validation_error_prevents_pdf_creation(self):
        payload = bill_payload(sample_args())
        initial, response, *_ = generator_replies(payload)
        envelope = json.loads(response[1])
        envelope["validationFieldErrors"] = [{"field": "name", "message": "invalid input"}]
        requester = Mock(side_effect=(initial, ("application/json", json.dumps(envelope).encode())))

        with self.assertRaises(GeneratorError):
            generate_pdf(payload, requester)

        self.assertEqual(requester.call_count, 2)

    def test_off_origin_download_is_rejected_before_request(self):
        payload = bill_payload(sample_args())
        requester = Mock(side_effect=generator_replies(payload, "https://example.com/foreign.pdf"))

        with self.assertRaises(GeneratorError):
            generate_pdf(payload, requester)

        self.assertEqual(requester.call_count, 5)

    def test_request_body_is_utf8_json_with_original_punctuation(self):
        payload = bill_payload(sample_args(extra=("-G", 'E\u0301preuves "bleues" + A/B & Fils',)))
        client = PostFinance()
        response = MagicMock()
        response.__enter__.return_value = response
        response.headers.get_content_type.return_value = "application/json"
        response.read.return_value = b"{}"
        with patch.object(client.opener, "open", return_value=response) as opener:
            client(f"{API_BASE}/writeAndValidate/paymentInformation", payload["paymentInformation"])

        request = opener.call_args.args[0]
        self.assertIn("charset=utf-8", request.get_header("Content-type"))
        self.assertIn("Épreuves".encode(), request.data)
        self.assertEqual(json.loads(request.data), payload["paymentInformation"])

    def test_invalid_pdf_does_not_replace_previous_output(self):
        with TemporaryDirectory() as directory:
            argv = sample_options(extra=("-d", directory))
            payload = bill_payload(parse_args(argv))
            requester = Mock(side_effect=generator_replies(payload, pdf_reply=(
                "application/pdf", b"%PDF-1.4\ntruncated response\n",
            )))
            output = Path(directory) / "Facture été.pdf"
            reference = Path(directory) / "crc_ref.csv"
            output.write_bytes(b"previous PDF")
            reference.write_text("previous reference", encoding="ascii")

            with patch("postfinance_qrbill.PostFinance", return_value=requester), redirect_stderr(io.StringIO()):
                self.assertEqual(main(argv), 2)

            self.assertEqual(requester.call_args_list[-1], call(DOWNLOAD_PATH))
            self.assertEqual(output.read_bytes(), b"previous PDF")
            self.assertEqual(reference.read_text(encoding="ascii"), "previous reference")

    def test_success_writes_pdf_and_legacy_sidecars(self):
        with TemporaryDirectory() as directory:
            argv = sample_options(QR_IBAN, ("-d", directory, "-M", "12,05", "-R", QR_REFERENCE))
            payload = bill_payload(parse_args(argv))
            requester = Mock(side_effect=generator_replies(payload))

            with patch("postfinance_qrbill.PostFinance", return_value=requester):
                self.assertEqual(main(argv), 0)

            output_directory = Path(directory)
            self.assertEqual((output_directory / "Facture été.pdf").read_bytes(), PDF_BYTES)
            for extension in ("csv", "html"):
                self.assertEqual((output_directory / f"crc_ref.{extension}").read_text(), QR_REFERENCE)
                self.assertEqual((output_directory / f"crc_amt.{extension}").read_text(), "0100000012056")


if __name__ == "__main__":
    unittest.main()
