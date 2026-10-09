import os
import golden_model


def read_rtl_output(filename):

    with open(filename, "r") as f:
        lines = [line.strip() for line in f.readlines() if line.strip()]

    return lines


def compare_frame(rtl_bits, ch0, ch1, ch2, ch3, frame_name):

    gm = golden_model.TDMGoldenModel()

    result = gm.run_frame(
        ch0,
        ch1,
        ch2,
        ch3
    )

    golden_stream = result["stream"]

    rtl_stream = [int(bit) for bit in rtl_bits]

    if len(golden_stream) != len(rtl_stream):

        print(
            f"[FAIL] {frame_name}: Length mismatch "
            f"(Golden={len(golden_stream)} RTL={len(rtl_stream)})"
        )

        return False

    for cycle in range(len(golden_stream)):

        if golden_stream[cycle] != rtl_stream[cycle]:

            print(f"\n[FAIL] {frame_name}")
            print(f"Cycle    : {cycle}")
            print(f"Expected : {golden_stream[cycle]}")
            print(f"Actual   : {rtl_stream[cycle]}")

            return False

    print(f"[PASS] {frame_name}")

    return True


def main():

    rtl_file = os.path.join(
        os.path.dirname(__file__),
        "..",
        "rtl_output.txt"
    )

    rtl_frames = read_rtl_output(rtl_file)

    if len(rtl_frames) < 2:
        print("ERROR: rtl_output.txt khong du 2 frame")
        return

    pass_count = 0

    if compare_frame(
        rtl_frames[0],
        0xA5,
        0x3C,
        0xF0,
        0x5A,
        "Frame 1 (A5 3C F0 5A)"
    ):
        pass_count += 1

    if compare_frame(
        rtl_frames[1],
        0x00,
        0xFF,
        0x81,
        0x7E,
        "Frame 2 (00 FF 81 7E)"
    ):
        pass_count += 1

    print("\n========================")
    print(f"PASS: {pass_count}/2 frames")

    if pass_count == 2:
        print(">>> ALL GOLDEN MODEL CHECKS PASSED")
    else:
        print(">>> GOLDEN MODEL CHECK FAILED")


if __name__ == "__main__":
    main()