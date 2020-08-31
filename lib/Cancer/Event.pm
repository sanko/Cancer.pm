package Cancer::Event 1.0 {
    use Moo;
    use Types::Standard qw[Int Num];
    use Time::HiRes;
    use PerlX::Define;

    #define TB_KEY_F1               (0xFFFF - 0);
    #define TB_KEY_F2               (0xFFFF - 1);
    #define TB_KEY_F3               (0xFFFF - 2);
    #define TB_KEY_F4               (0xFFFF - 3);
    #define TB_KEY_F5               (0xFFFF - 4);
    #define TB_KEY_F6               (0xFFFF - 5);
    #define TB_KEY_F7               (0xFFFF - 6);
    #define TB_KEY_F8               (0xFFFF - 7);
    #define TB_KEY_F9               (0xFFFF - 8);
    #define TB_KEY_F10              (0xFFFF - 9);
    #define TB_KEY_F11              (0xFFFF - 10);
    #define TB_KEY_F12              (0xFFFF - 11);
    #define TB_KEY_INSERT           (0xFFFF - 12);
    #define TB_KEY_DELETE           (0xFFFF - 13);
    #define TB_KEY_HOME             (0xFFFF - 14);
    #define TB_KEY_END              (0xFFFF - 15);
    #define TB_KEY_PGUP             (0xFFFF - 16);
    #define TB_KEY_PGDN             (0xFFFF - 17);
    #define TB_KEY_ARROW_UP         (0xFFFF - 18);
    #define TB_KEY_ARROW_DOWN       (0xFFFF - 19);
    #define TB_KEY_ARROW_LEFT       (0xFFFF - 20);
    #define TB_KEY_ARROW_RIGHT      (0xFFFF - 21);
    define TB_KEY_MOUSE_LEFT       => ( 0xFFFF - 22 );
    define TB_KEY_MOUSE_RIGHT      => ( 0xFFFF - 23 );
    define TB_KEY_MOUSE_MIDDLE     => ( 0xFFFF - 24 );
    define TB_KEY_MOUSE_RELEASE    => ( 0xFFFF - 25 );
    define TB_KEY_MOUSE_WHEEL_UP   => ( 0xFFFF - 26 );
    define TB_KEY_MOUSE_WHEEL_DOWN => ( 0xFFFF - 27 );
    #
    # Alt modifier constant, see tb_event.mod field and tb_select_input_mode
    # function. Mouse-motion modifier
    define TB_MOD_ALT    => 0x01;
    define TB_MOD_MOTION => 0x02;
    #
    has time => ( is => 'ro', isa => Num, default => sub { Time::HiRes::time() } );

    #has [qw[type mod key ch x y]] => ( is => 'rw', isa => Int );
};
1;
