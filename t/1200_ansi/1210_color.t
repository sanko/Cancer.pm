use Test2::V1 -ipP;
use blib;
use Cancer::Ansi qw[color_to_hex_string hex_to_rgb ansi_to_rgb convert_256];
#
subtest hex_to_rgb => sub {
    is [ hex_to_rgb(0x0000ff) ], [ 0,   0,   255 ], '0x0000ff';
    is [ hex_to_rgb(0xffffff) ], [ 255, 255, 255 ], '0xffffff';
    is [ hex_to_rgb(0xff0000) ], [ 255, 0,   0 ],   '0xff0000';
};
subtest color_to_hex_string => sub {
    is color_to_hex_string(0x0000ff), '#0000ff', q[color_to_hex_string('#0000ff')];
    is color_to_hex_string(0xffffff), '#ffffff', q[color_to_hex_string('#ffffff')];
    is color_to_hex_string(0xff0000), '#ff0000', q[color_to_hex_string('#ff0000')];
};
subtest ansi_to_rgb => sub {
    is [ ansi_to_rgb(0) ],   [ 0x00, 0x00, 0x00 ], 'ansi_to_rgb(0)';
    is [ ansi_to_rgb(1) ],   [ 0x80, 0x00, 0x00 ], 'ansi_to_rgb(1)';
    is [ ansi_to_rgb(255) ], [ 0xee, 0xee, 0xee ], 'ansi_to_rgb(255)';
};
subtest hex_to_rgb => sub {
    is [ hex_to_rgb(0x0000FF) ], [ 0,   0,   255 ], q[hex_to_rgb('0x0000FF')];
    is [ hex_to_rgb(0xFFFFFF) ], [ 255, 255, 255 ], q[hex_to_rgb('0xFFFFFF')];
    is [ hex_to_rgb(0xFF0000) ], [ 255, 0,   0 ],   q[hex_to_rgb('0xFF0000')];
};
subtest convert_256 => sub {
    is convert_256( hex 'ffffff' ), 231, '#ffffff -> white';
    is convert_256( hex 'eeeeee' ), 255, '#eeeeee -> offwhite';
    is convert_256( hex 'f2f2f2' ), 255, '#f2f2f2 -> slightly brighter than offwhite';
    is convert_256( hex 'ff0000' ), 196, '#ff0000 -> red';
    is convert_256( hex 'afafaf' ), 145, '#afafaf -> silver foil';
    is convert_256( hex 'b2b2b2' ), 249, '#b2b2b2 -> silver chalice';
    is convert_256( hex 'b0b0b0' ), 145, '#b0b0b0 -> slightly closer to silver foil';
    is convert_256( hex 'b1b1b1' ), 249, '#b1b1b1 -> slightly closer to silver chalice';
    is convert_256( hex '808080' ), 244, '#808080 -> grey';
};
#
done_testing;
