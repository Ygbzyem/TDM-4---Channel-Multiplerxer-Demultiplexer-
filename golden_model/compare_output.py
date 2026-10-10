import os

import golden_model

from timing_checker import(
    check_frame_length
)

from latency_checker import(
    report_latency
)

from report_generator import(
    write_report
)


def read_rtl_output(filename):

    with open(
        filename,
        "r"
    ) as f:

        lines = [
            line.strip()
            for line in f.readlines()
            if line.strip()
        ]

    return lines


def compare_hex_frame(
    rtl_bits,
    ch0,
    ch1,
    ch2,
    ch3
):

    gm = golden_model.TDMGoldenModel()

    result = gm.run_frame(
        ch0,
        ch1,
        ch2,
        ch3
    )

    golden_stream = result["stream"]

    rtl_stream = [
        int(bit)
        for bit in rtl_bits
    ]

    check_frame_length(
        golden_stream
    )

    expected_frame = (
        (ch0 << 24)
        | (ch1 << 16)
        | (ch2 << 8)
        | ch3
    )

    actual_frame = int(
        rtl_bits,
        2
    )

    print(
        "\n=== HEX FRAME CHECK ==="
    )

    print(
        f"Expected : 0x{expected_frame:08X}"
    )

    print(
        f"RTL      : 0x{actual_frame:08X}"
    )

    if expected_frame == actual_frame:

        print("PASS")

        report_latency()

        write_report(
            "verification_report.txt",
            actual_frame,
            expected_frame,
            len(golden_stream),
            1000
        )

        return True

    print("FAIL")

    return False


def main():

    rtl_file = os.path.join(
        os.path.dirname(__file__),
        "..",
        "rtl_output.txt"
    )

    rtl_frames = read_rtl_output(
        rtl_file
    )

    compare_hex_frame(
        rtl_frames[0],
        0xA5,
        0x3C,
        0xF0,
        0x5A
    )


if __name__ == "__main__":
    main()
