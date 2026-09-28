// =============================================================
// Module      : tdm_top
// Vai tro     : Noi day ca 5 module con lai voi nhau + lop "glue"
//               bu do tre 1 chu ky cua cac thanh ghi dong bo, de
//               he thong chay dung: khong mat bit, khong lech kenh,
//               va CH0 la kenh dau tien xuat hien sau reset.
//
// 5 module con (tdm_counter, tdm_mux, tx_shift_reg, rx_shift_reg,
// tdm_demux) GIU NGUYEN nhu ban thanh vien viet - khong sua logic
// ben trong. Toan bo "meo" de he thong chay dung nam GOM HET vao
// day, o dung 3 dong duoi day:
//
//   mux_select    = (bit_count + 1)[4:3]   -- nhin truoc 1 buoc
//   load          = bit_count[2:0] == 3'b111
//   byte_boundary = bit_count[2:0] == 3'b111
//   demux_select  = channel_select, TRE 1 chu ky (thanh ghi rieng)
//
// TAI SAO CAN 4 DONG NAY (tom tat - xem docs/tdm_top.md de biet chi
// tiet + vi du so):
//
//   1) tx_shift_reg chi "load" duoc dung luc canh clock toi, nen
//      muon no phat dung byte cua kenh X trong suot 8 clock cua
//      slot X, phai bao no truoc 1 buoc (nhin channel_select cua
//      slot KE TIEP, khong phai slot hien tai).
//
//   2) load/byte_boundary phai no o CUOI slot (bit[2:0]==7), khong
//      phai o dau slot (==0) - neu dat o dau slot, byte se bi phat
//      tre mat 1 nhip so voi khung cua no, gay LECH KENH khi ghi ra
//      demux (da kiem chung bang mo phong, xem docs/tdm_top.md).
//
//   3) Dung luc byte_done bat len 1, channel_select "song" (lay
//      thang tu tdm_counter) da nhay sang kenh KE TIEP mat roi (vi
//      bit_count khong dung lai cho ai ca). Neu demux doc thang gia
//      tri song do, no se ghi byte vua xong vao SAI kenh (kenh ke
//      tiep). Phai dung 1 thanh ghi rieng (demux_select) de "giu
//      lai" dung gia tri channel_select cua 1 chu ky TRUOC, luc byte
//      do van con dung.
// =============================================================

module tdm_top (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] CH0,
    input  wire [7:0] CH1,
    input  wire [7:0] CH2,
    input  wire [7:0] CH3,
    output wire       TDM_DATA,
    output wire [7:0] CH0_OUT,
    output wire [7:0] CH1_OUT,
    output wire [7:0] CH2_OUT,
    output wire [7:0] CH3_OUT
);

    // -----------------------------------------------------------
    // Nguon dong ho/dem duy nhat
    // -----------------------------------------------------------
    wire [4:0] bit_count;
    wire [1:0] channel_select;   // "song" - dung cho MUX (qua mux_select), KHONG dung thang cho DEMUX

    tdm_counter u_counter (
        .clk            (clk),
        .rst            (rst),
        .bit_count      (bit_count),
        .channel_select (channel_select)
    );

    // -----------------------------------------------------------
    // Lop glue: suy ra 3 tin hieu can thiet tu bit_count/channel_select
    // -----------------------------------------------------------
    wire [4:0] bit_count_next = bit_count + 5'd1;
    wire [1:0] mux_select     = bit_count_next[4:3];       // nhin truoc 1 buoc, cho MUX/TX

    wire load          = (bit_count[2:0] == 3'b111);       // no o CUOI slot
    wire byte_boundary = (bit_count[2:0] == 3'b111);       // load va byte_boundary la CUNG 1 cong thuc

    reg  [1:0] demux_select;                               // "anh chup", tre 1 chu ky so voi channel_select
    always @(posedge clk) begin
        if (rst)
            demux_select <= 2'b00;
        else
            demux_select <= channel_select;
    end

    // -----------------------------------------------------------
    // Duong du lieu: mux -> tx_shift_reg -> TDM_DATA -> rx_shift_reg -> demux
    // -----------------------------------------------------------
    wire [7:0] mux_out;
    wire [7:0] rx_data;
    wire       byte_done;

    tdm_mux u_mux (
        .CH0            (CH0),
        .CH1            (CH1),
        .CH2            (CH2),
        .CH3            (CH3),
        .channel_select (mux_select),
        .mux_out        (mux_out)
    );

    tx_shift_reg u_tx (
        .clk        (clk),
        .rst        (rst),
        .mux_out    (mux_out),
        .load       (load),
        .serial_out (TDM_DATA)
    );

    rx_shift_reg u_rx (
        .clk           (clk),
        .rst           (rst),
        .serial_data   (TDM_DATA),
        .byte_boundary (byte_boundary),
        .rx_data       (rx_data),
        .byte_done     (byte_done)
    );

    tdm_demux u_demux (
        .clk            (clk),
        .rst            (rst),
        .rx_data        (rx_data),
        .channel_select (demux_select),   // <-- ban da tre 1 chu ky, KHONG PHAI channel_select song o tren
        .byte_done      (byte_done),
        .CH0_OUT        (CH0_OUT),
        .CH1_OUT        (CH1_OUT),
        .CH2_OUT        (CH2_OUT),
        .CH3_OUT        (CH3_OUT)
    );

endmodule
