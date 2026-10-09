class TDMCycleModel:

    def __init__(self):

        self.bit_count = 0

    def run_frame(self, ch0, ch1, ch2, ch3):

        channels = [
            ch0,
            ch1,
            ch2,
            ch3
        ]

        serial_stream = []

        for channel in channels:

            for bit in range(7, -1, -1):

                serial_stream.append(
                    (channel >> bit) & 1
                )

        return serial_stream


def print_cycles(stream):

    print("CLK | DATA")

    for clk, bit in enumerate(stream):

        print(f"{clk:02d}  |  {bit}")


if __name__ == "__main__":

    model = TDMCycleModel()

    stream = model.run_frame(
        0x12,
        0x34,
        0x56,
        0x78
    )

    print_cycles(stream)