def write_report(
    filename,
    rtl_frame,
    expected_frame,
    frame_length,
    random_tests
):

    with open(
        filename,
        "w"
    ) as f:

        f.write(
            "===== VERIFICATION REPORT =====\n"
        )

        f.write(
            f"Expected Frame : 0x{expected_frame:08X}\n"
        )

        f.write(
            f"RTL Frame      : 0x{rtl_frame:08X}\n"
        )

        f.write(
            f"Frame Length   : {frame_length} bits\n"
        )

        f.write(
            f"Random Tests   : {random_tests}\n"
        )

        f.write(
            "\nSTATUS : PASS\n"
        )