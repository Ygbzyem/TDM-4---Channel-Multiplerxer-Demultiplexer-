from pathlib import Path


def read_hex_file(filename):
    path = Path(filename)

    if not path.exists():
        raise FileNotFoundError(f"Cannot find file: {filename}")

    with open(path, "r") as f:
        return [
            line.strip().lower()
            for line in f
            if line.strip()
        ]


def compare_files(input_file, output_file):

    expected_vectors = read_hex_file(input_file)
    actual_vectors = read_hex_file(output_file)

    print("\n" + "=" * 60)
    print("FILE-BASED RTL COMPARISON")
    print("=" * 60)

    total_vectors = max(
        len(expected_vectors),
        len(actual_vectors)
    )

    errors = 0

    for i in range(total_vectors):

        expected = (
            expected_vectors[i]
            if i < len(expected_vectors)
            else "<missing>"
        )

        actual = (
            actual_vectors[i]
            if i < len(actual_vectors)
            else "<missing>"
        )

        print(f"\nVECTOR #{i}")

        print(
            f"Expected : 0x{expected.upper()}"
        )

        print(
            f"Actual   : 0x{actual.upper()}"
        )

        if expected == actual:

            print("Result   : PASS")

        else:

            print("Result   : FAIL")

            errors += 1

    print("\n" + "=" * 60)

    print(
        f"Total vectors : {total_vectors}"
    )

    print(
        f"Passed        : {total_vectors - errors}"
    )

    print(
        f"Failed        : {errors}"
    )

    print("=" * 60)

    if errors == 0:

        print(
            "\n>>> ALL VECTORS PASSED"
        )

        generate_report(
            total_vectors,
            errors
        )

    else:

        print(
            f"\n>>> {errors} VECTOR(S) FAILED"
        )


def generate_report(
    total_vectors,
    errors
):

    report_file = (
        Path(__file__).parent
        / "verification_logs"
        / "verification_report.md"
    )

    with open(
        report_file,
        "w"
    ) as f:

        f.write(
            "# Verification Report\n\n"
        )

        f.write(
            f"Total vectors: {total_vectors}\n\n"
        )

        f.write(
            f"Passed: {total_vectors - errors}\n\n"
        )

        f.write(
            f"Failed: {errors}\n\n"
        )

        f.write(
            "Status: PASS\n"
        )

    print(
        f"\nReport generated: {report_file}"
    )


if __name__ == "__main__":

    compare_files(
        "input/input_vectors.hex",
        "golden_model/verification_logs/rtl_output_vectors.hex"
    )