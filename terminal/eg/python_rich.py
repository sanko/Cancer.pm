#~ from rich import print
from rich.console import Console
from rich import inspect
from rich.color import Color

console = Console(color_system="truecolor")

fragments = list(console.render("'[bold blink2 red on #ffffff]foo[/bold blink2 red on #ffffff]'"))

inspect(fragments)
#~ https://github.com/Textualize/rich/blob/26152e9cc95eef9c8f363d7bf1dfda426275348d/rich/segment.py#L56
