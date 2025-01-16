from sense.metabase.exceptions import sanitise_error_message


def test_sanitise_error_message_with_uuid():
    result = sanitise_error_message(
        "I have a 4d0a6c94-cedc-4d1d-a6fa-0e7e68137501."
    )

    assert result == "I have a ."


def test_sanitise_error_message_without_uuid():
    result = sanitise_error_message("I have a 4d0a6c94-cedc-4d1d.")

    assert result == "I have a 4d0a6c94-cedc-4d1d."
