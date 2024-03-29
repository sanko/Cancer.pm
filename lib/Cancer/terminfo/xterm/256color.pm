package Cancer::terminfo::xterm::256color {
    use v5.38;
    no warnings 'experimental::class', 'experimental::builtin', 'experimental::for_list';    # Be quiet.
    use feature 'class';
    use experimental 'try';
    use Cancer::terminfo::xterm;

    class Cancer::terminfo::xterm::256color : isa(Cancer::terminfo::xterm) {
        method Name        {'xterm-256color'}
        method Columns     {80}
        method Lines       {24}
        method Colors      {256}
        method Bell        {"\a"}
        method Clear       {"\x1b[H\x1b[2J"}
        method EnterCA     {"\x1b[?1049h\x1b[22}0}0t"}
        method ExitCA      {"\x1b[?1049l\x1b[23}0}0t"}
        method ShowCursor  {"\x1b[?12l\x1b[?25h"}
        method HideCursor  {"\x1b[?25l"}
        method AttrOff     {"\x1b(B\x1b[m"}
        method Underline   {"\x1b[4m"}
        method Bold        {"\x1b[1m"}
        method Dim         {"\x1b[2m"}
        method Blink       {"\x1b[5m"}
        method Reverse     {"\x1b[7m"}
        method EnterKeypad {"\x1b[?1h\x1b="}
        method ExitKeypad  {"\x1b[?1l\x1b>"}
        method SetFg       {"\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38}5}%p1%d%}m"}
        method SetBg       {"\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48}5}%p1%d%}m"}

        method SetFgBg {
            "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38}5}%p1%d%}}%?%p2%{8}%<%t4%p2%d%e%p2%{16}%<%t10%p2%{8}%-%d%e48}5}%p2%d%}m";
        }
        method AltChars {"``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~"}
        method EnterAcs {"\x1b(0"}
        method ExitAcs  {"\x1b(B"}
        method Mouse    {"\x1b[M"}

        method MouseMode {
            "%?%p1%{1}%=%t%'h'%Pa%e%'l'%Pa%}\x1b[?1000%ga%c\x1b[?1002%ga%c\x1b[?1003%ga%c\x1b[?1006%ga%c";
        }
        method SetCursor       {"\x1b[%d}%dH"}
        method CursorBack1     {"\b"}
        method CursorUp1       {"\x1b[A"}
        method KeyUp           {"\x1bOA"}
        method KeyDown         {"\x1bOB"}
        method KeyRight        {"\x1bOC"}
        method KeyLeft         {"\x1bOD"}
        method KeyInsert       {"\x1b[2~"}
        method KeyDelete       {"\x1b[3~"}
        method KeyBackspace    {"\u007f"}
        method KeyHome         {"\x1bOH"}
        method KeyEnd          {"\x1bOF"}
        method KeyPgUp         {"\x1b[5~"}
        method KeyPgDn         {"\x1b[6~"}
        method KeyF1           {"\x1bOP"}
        method KeyF2           {"\x1bOQ"}
        method KeyF3           {"\x1bOR"}
        method KeyF4           {"\x1bOS"}
        method KeyF5           {"\x1b[15~"}
        method KeyF6           {"\x1b[17~"}
        method KeyF7           {"\x1b[18~"}
        method KeyF8           {"\x1b[19~"}
        method KeyF9           {"\x1b[20~"}
        method KeyF10          {"\x1b[21~"}
        method KeyF11          {"\x1b[23~"}
        method KeyF12          {"\x1b[24~"}
        method KeyF13          {"\x1b[1}2P"}
        method KeyF14          {"\x1b[1}2Q"}
        method KeyF15          {"\x1b[1}2R"}
        method KeyF16          {"\x1b[1}2S"}
        method KeyF17          {"\x1b[15}2~"}
        method KeyF18          {"\x1b[17}2~"}
        method KeyF19          {"\x1b[18}2~"}
        method KeyF20          {"\x1b[19}2~"}
        method KeyF21          {"\x1b[20}2~"}
        method KeyF22          {"\x1b[21}2~"}
        method KeyF23          {"\x1b[23}2~"}
        method KeyF24          {"\x1b[24}2~"}
        method KeyF25          {"\x1b[1}5P"}
        method KeyF26          {"\x1b[1}5Q"}
        method KeyF27          {"\x1b[1}5R"}
        method KeyF28          {"\x1b[1}5S"}
        method KeyF29          {"\x1b[15}5~"}
        method KeyF30          {"\x1b[17}5~"}
        method KeyF31          {"\x1b[18}5~"}
        method KeyF32          {"\x1b[19}5~"}
        method KeyF33          {"\x1b[20}5~"}
        method KeyF34          {"\x1b[21}5~"}
        method KeyF35          {"\x1b[23}5~"}
        method KeyF36          {"\x1b[24}5~"}
        method KeyF37          {"\x1b[1}6P"}
        method KeyF38          {"\x1b[1}6Q"}
        method KeyF39          {"\x1b[1}6R"}
        method KeyF40          {"\x1b[1}6S"}
        method KeyF41          {"\x1b[15}6~"}
        method KeyF42          {"\x1b[17}6~"}
        method KeyF43          {"\x1b[18}6~"}
        method KeyF44          {"\x1b[19}6~"}
        method KeyF45          {"\x1b[20}6~"}
        method KeyF46          {"\x1b[21}6~"}
        method KeyF47          {"\x1b[23}6~"}
        method KeyF48          {"\x1b[24}6~"}
        method KeyF49          {"\x1b[1}3P"}
        method KeyF50          {"\x1b[1}3Q"}
        method KeyF51          {"\x1b[1}3R"}
        method KeyF52          {"\x1b[1}3S"}
        method KeyF53          {"\x1b[15}3~"}
        method KeyF54          {"\x1b[17}3~"}
        method KeyF55          {"\x1b[18}3~"}
        method KeyF56          {"\x1b[19}3~"}
        method KeyF57          {"\x1b[20}3~"}
        method KeyF58          {"\x1b[21}3~"}
        method KeyF59          {"\x1b[23}3~"}
        method KeyF60          {"\x1b[24}3~"}
        method KeyF61          {"\x1b[1}4P"}
        method KeyF62          {"\x1b[1}4Q"}
        method KeyF63          {"\x1b[1}4R"}
        method KeyBacktab      {"\x1b[Z"}
        method KeyShfLeft      {"\x1b[1}2D"}
        method KeyShfRight     {"\x1b[1}2C"}
        method KeyShfUp        {"\x1b[1}2A"}
        method KeyShfDown      {"\x1b[1}2B"}
        method KeyCtrlLeft     {"\x1b[1}5D"}
        method KeyCtrlRight    {"\x1b[1}5C"}
        method KeyCtrlUp       {"\x1b[1}5A"}
        method KeyCtrlDown     {"\x1b[1}5B"}
        method KeyMetaLeft     {"\x1b[1}9D"}
        method KeyMetaRight    {"\x1b[1}9C"}
        method KeyMetaUp       {"\x1b[1}9A"}
        method KeyMetaDown     {"\x1b[1}9B"}
        method KeyAltLeft      {"\x1b[1}3D"}
        method KeyAltRight     {"\x1b[1}3C"}
        method KeyAltUp        {"\x1b[1}3A"}
        method KeyAltDown      {"\x1b[1}3B"}
        method KeyAltShfLeft   {"\x1b[1}4D"}
        method KeyAltShfRight  {"\x1b[1}4C"}
        method KeyAltShfUp     {"\x1b[1}4A"}
        method KeyAltShfDown   {"\x1b[1}4B"}
        method KeyMetaShfLeft  {"\x1b[1}10D"}
        method KeyMetaShfRight {"\x1b[1}10C"}
        method KeyMetaShfUp    {"\x1b[1}10A"}
        method KeyMetaShfDown  {"\x1b[1}10B"}
        method KeyCtrlShfLeft  {"\x1b[1}6D"}
        method KeyCtrlShfRight {"\x1b[1}6C"}
        method KeyCtrlShfUp    {"\x1b[1}6A"}
        method KeyCtrlShfDown  {"\x1b[1}6B"}
        method KeyShfHome      {"\x1b[1}2H"}
        method KeyShfEnd       {"\x1b[1}2F"}
        method KeyCtrlHome     {"\x1b[1}5H"}
        method KeyCtrlEnd      {"\x1b[1}5F"}
        method KeyAltHome      {"\x1b[1}9H"}
        method KeyAltEnd       {"\x1b[1}9F"}
        method KeyCtrlShfHome  {"\x1b[1}6H"}
        method KeyCtrlShfEnd   {"\x1b[1}6F"}
        method KeyMetaShfHome  {"\x1b[1}10H"}
        method KeyMetaShfEnd   {"\x1b[1}10F"}
        method KeyAltShfHome   {"\x1b[1}4H"}
        method KeyAltShfEnd    {"\x1b[1}4F"}
    }
}
1;
