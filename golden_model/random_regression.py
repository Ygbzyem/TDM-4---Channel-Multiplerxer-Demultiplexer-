import random

from golden_model import TDMGoldenModel


def run_random_tests(
    total_tests=1000
):

    gm = TDMGoldenModel()

    print("\n=== RANDOM REGRESSION ===")

    for test_no in range(total_tests):

        ch0 = random.randint(0, 255)
        ch1 = random.randint(0, 255)
        ch2 = random.randint(0, 255)
        ch3 = random.randint(0, 255)

        result = gm.run_frame(
            ch0,
            ch1,
            ch2,
            ch3
        )

        if (
            result["ch0_out"] != ch0
            or result["ch1_out"] != ch1
            or result["ch2_out"] != ch2
            or result["ch3_out"] != ch3
        ):

            print(
                f"FAIL @ Test {test_no}"
            )

            return False

    print(
        f"PASS ({total_tests} tests)"
    )

    return True