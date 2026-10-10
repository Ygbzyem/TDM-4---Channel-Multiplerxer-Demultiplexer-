FRAME_BITS = 32


def check_frame_length(stream):

    actual_length = len(stream)

    print("\n=== FRAME LENGTH CHECK ===")

    print(
        f"Expected Length : {FRAME_BITS} bits"
    )

    print(
        f"Actual Length   : {actual_length} bits"
    )

    if actual_length == FRAME_BITS:

        print("PASS")

        return True

    print("FAIL")

    return False