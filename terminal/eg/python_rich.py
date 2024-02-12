#~ from rich import print
from rich.console import Console
from rich import inspect, print
from rich.color import Color

console = Console(color_system="truecolor")

text = "[red] red [uu]f[black]o[/]o[/uu]"

fragments = list(console.render(text))

inspect(fragments)
#~ https://github.com/Textualize/rich/blob/26152e9cc95eef9c8f363d7bf1dfda426275348d/rich/segment.py#L56

print(text)
