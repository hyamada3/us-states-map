import webbrowser
import os

html_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'us_map.html')
webbrowser.open(f'file:///{html_path.replace(os.sep, "/")}')
print(f'地図を開きました: {html_path}')