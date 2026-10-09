class TDMGoldenModel:

    def serialize(self, channels):

        stream = []

        for byte in channels:
            for i in range(7, -1, -1):
                bit = (byte >> i) & 1
                stream.append(bit)

        return stream

    def deserialize(self, stream):

        outputs = []

        for i in range(0, len(stream), 8):

            byte = 0

            for bit in stream[i:i+8]:
                byte = (byte << 1) | bit

            outputs.append(byte)

        return outputs

    def run_frame(self, ch0, ch1, ch2, ch3):

        tx_channels = [
            ch0,
            ch1,
            ch2,
            ch3
        ]

        stream = self.serialize(tx_channels)

        recovered = self.deserialize(stream)

        return {
            "stream": stream,
            "ch0_out": recovered[0],
            "ch1_out": recovered[1],
            "ch2_out": recovered[2],
            "ch3_out": recovered[3]
        }


if __name__ == "__main__":

    gm = TDMGoldenModel()

    result = gm.run_frame(
        0x12,
        0x34,
        0x56,
        0x78
    )

    print("TDM Stream:")
    print(result["stream"])

    print("\nRecovered Data:")
    print(hex(result["ch0_out"]))
    print(hex(result["ch1_out"]))
    print(hex(result["ch2_out"]))
    print(hex(result["ch3_out"]))

    if (
        result["ch0_out"] == 0x12 and
        result["ch1_out"] == 0x34 and
        result["ch2_out"] == 0x56 and
        result["ch3_out"] == 0x78
    ):
        print("\nPASS")
    else:
        print("\nFAIL")


