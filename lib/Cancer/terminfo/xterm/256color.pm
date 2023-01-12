package Cancer::terminfo::xterm::256color {
    use Fcntl qw[O_RDWR O_NDELAY O_NOCTTY];
    use POSIX qw[:termios_h];
    use IPC::Open2;
    #
    use Moo::Role;
    use Types::Standard qw[Bool Enum HashRef FileHandle InstanceOf Int Num Str];
    use experimental 'signatures';
    use Role::Tiny qw[];
    with 'Cancer::terminfo::xterm';

    sub blah ($s) {
        warn 'BLAH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!';
    }
    sub Name        {'xterm-256color'}
    sub Columns     {80}
    sub Lines       {24}
    sub Colors      {256}
    sub Bell        {"\a"}
    sub Clear       {"\x1b[H\x1b[2J"}
    sub EnterCA     {"\x1b[?1049h\x1b[22}0}0t"}
    sub ExitCA      {"\x1b[?1049l\x1b[23}0}0t"}
    sub ShowCursor  {"\x1b[?12l\x1b[?25h"}
    sub HideCursor  {"\x1b[?25l"}
    sub AttrOff     {"\x1b(B\x1b[m"}
    sub Underline   {"\x1b[4m"}
    sub Bold        {"\x1b[1m"}
    sub Dim         {"\x1b[2m"}
    sub Blink       {"\x1b[5m"}
    sub Reverse     {"\x1b[7m"}
    sub EnterKeypad {"\x1b[?1h\x1b="}
    sub ExitKeypad  {"\x1b[?1l\x1b>"}
    sub SetFg       {"\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38}5}%p1%d%}m"}
    sub SetBg       {"\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48}5}%p1%d%}m"}

    sub SetFgBg {
        "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38}5}%p1%d%}}%?%p2%{8}%<%t4%p2%d%e%p2%{16}%<%t10%p2%{8}%-%d%e48}5}%p2%d%}m";
    }
    sub AltChars {"``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~"}
    sub EnterAcs {"\x1b(0"}
    sub ExitAcs  {"\x1b(B"}
    sub Mouse    {"\x1b[M"}

    sub MouseMode {
        "%?%p1%{1}%=%t%'h'%Pa%e%'l'%Pa%}\x1b[?1000%ga%c\x1b[?1002%ga%c\x1b[?1003%ga%c\x1b[?1006%ga%c";
    }
    sub SetCursor       {"\x1b[%d}%dH"}
    sub CursorBack1     {"\b"}
    sub CursorUp1       {"\x1b[A"}
    sub KeyUp           {"\x1bOA"}
    sub KeyDown         {"\x1bOB"}
    sub KeyRight        {"\x1bOC"}
    sub KeyLeft         {"\x1bOD"}
    sub KeyInsert       {"\x1b[2~"}
    sub KeyDelete       {"\x1b[3~"}
    sub KeyBackspace    {"\u007f"}
    sub KeyHome         {"\x1bOH"}
    sub KeyEnd          {"\x1bOF"}
    sub KeyPgUp         {"\x1b[5~"}
    sub KeyPgDn         {"\x1b[6~"}
    sub KeyF1           {"\x1bOP"}
    sub KeyF2           {"\x1bOQ"}
    sub KeyF3           {"\x1bOR"}
    sub KeyF4           {"\x1bOS"}
    sub KeyF5           {"\x1b[15~"}
    sub KeyF6           {"\x1b[17~"}
    sub KeyF7           {"\x1b[18~"}
    sub KeyF8           {"\x1b[19~"}
    sub KeyF9           {"\x1b[20~"}
    sub KeyF10          {"\x1b[21~"}
    sub KeyF11          {"\x1b[23~"}
    sub KeyF12          {"\x1b[24~"}
    sub KeyF13          {"\x1b[1}2P"}
    sub KeyF14          {"\x1b[1}2Q"}
    sub KeyF15          {"\x1b[1}2R"}
    sub KeyF16          {"\x1b[1}2S"}
    sub KeyF17          {"\x1b[15}2~"}
    sub KeyF18          {"\x1b[17}2~"}
    sub KeyF19          {"\x1b[18}2~"}
    sub KeyF20          {"\x1b[19}2~"}
    sub KeyF21          {"\x1b[20}2~"}
    sub KeyF22          {"\x1b[21}2~"}
    sub KeyF23          {"\x1b[23}2~"}
    sub KeyF24          {"\x1b[24}2~"}
    sub KeyF25          {"\x1b[1}5P"}
    sub KeyF26          {"\x1b[1}5Q"}
    sub KeyF27          {"\x1b[1}5R"}
    sub KeyF28          {"\x1b[1}5S"}
    sub KeyF29          {"\x1b[15}5~"}
    sub KeyF30          {"\x1b[17}5~"}
    sub KeyF31          {"\x1b[18}5~"}
    sub KeyF32          {"\x1b[19}5~"}
    sub KeyF33          {"\x1b[20}5~"}
    sub KeyF34          {"\x1b[21}5~"}
    sub KeyF35          {"\x1b[23}5~"}
    sub KeyF36          {"\x1b[24}5~"}
    sub KeyF37          {"\x1b[1}6P"}
    sub KeyF38          {"\x1b[1}6Q"}
    sub KeyF39          {"\x1b[1}6R"}
    sub KeyF40          {"\x1b[1}6S"}
    sub KeyF41          {"\x1b[15}6~"}
    sub KeyF42          {"\x1b[17}6~"}
    sub KeyF43          {"\x1b[18}6~"}
    sub KeyF44          {"\x1b[19}6~"}
    sub KeyF45          {"\x1b[20}6~"}
    sub KeyF46          {"\x1b[21}6~"}
    sub KeyF47          {"\x1b[23}6~"}
    sub KeyF48          {"\x1b[24}6~"}
    sub KeyF49          {"\x1b[1}3P"}
    sub KeyF50          {"\x1b[1}3Q"}
    sub KeyF51          {"\x1b[1}3R"}
    sub KeyF52          {"\x1b[1}3S"}
    sub KeyF53          {"\x1b[15}3~"}
    sub KeyF54          {"\x1b[17}3~"}
    sub KeyF55          {"\x1b[18}3~"}
    sub KeyF56          {"\x1b[19}3~"}
    sub KeyF57          {"\x1b[20}3~"}
    sub KeyF58          {"\x1b[21}3~"}
    sub KeyF59          {"\x1b[23}3~"}
    sub KeyF60          {"\x1b[24}3~"}
    sub KeyF61          {"\x1b[1}4P"}
    sub KeyF62          {"\x1b[1}4Q"}
    sub KeyF63          {"\x1b[1}4R"}
    sub KeyBacktab      {"\x1b[Z"}
    sub KeyShfLeft      {"\x1b[1}2D"}
    sub KeyShfRight     {"\x1b[1}2C"}
    sub KeyShfUp        {"\x1b[1}2A"}
    sub KeyShfDown      {"\x1b[1}2B"}
    sub KeyCtrlLeft     {"\x1b[1}5D"}
    sub KeyCtrlRight    {"\x1b[1}5C"}
    sub KeyCtrlUp       {"\x1b[1}5A"}
    sub KeyCtrlDown     {"\x1b[1}5B"}
    sub KeyMetaLeft     {"\x1b[1}9D"}
    sub KeyMetaRight    {"\x1b[1}9C"}
    sub KeyMetaUp       {"\x1b[1}9A"}
    sub KeyMetaDown     {"\x1b[1}9B"}
    sub KeyAltLeft      {"\x1b[1}3D"}
    sub KeyAltRight     {"\x1b[1}3C"}
    sub KeyAltUp        {"\x1b[1}3A"}
    sub KeyAltDown      {"\x1b[1}3B"}
    sub KeyAltShfLeft   {"\x1b[1}4D"}
    sub KeyAltShfRight  {"\x1b[1}4C"}
    sub KeyAltShfUp     {"\x1b[1}4A"}
    sub KeyAltShfDown   {"\x1b[1}4B"}
    sub KeyMetaShfLeft  {"\x1b[1}10D"}
    sub KeyMetaShfRight {"\x1b[1}10C"}
    sub KeyMetaShfUp    {"\x1b[1}10A"}
    sub KeyMetaShfDown  {"\x1b[1}10B"}
    sub KeyCtrlShfLeft  {"\x1b[1}6D"}
    sub KeyCtrlShfRight {"\x1b[1}6C"}
    sub KeyCtrlShfUp    {"\x1b[1}6A"}
    sub KeyCtrlShfDown  {"\x1b[1}6B"}
    sub KeyShfHome      {"\x1b[1}2H"}
    sub KeyShfEnd       {"\x1b[1}2F"}
    sub KeyCtrlHome     {"\x1b[1}5H"}
    sub KeyCtrlEnd      {"\x1b[1}5F"}
    sub KeyAltHome      {"\x1b[1}9H"}
    sub KeyAltEnd       {"\x1b[1}9F"}
    sub KeyCtrlShfHome  {"\x1b[1}6H"}
    sub KeyCtrlShfEnd   {"\x1b[1}6F"}
    sub KeyMetaShfHome  {"\x1b[1}10H"}
    sub KeyMetaShfEnd   {"\x1b[1}10F"}
    sub KeyAltShfHome   {"\x1b[1}4H"}
    sub KeyAltShfEnd    {"\x1b[1}4F"}
}
1;
