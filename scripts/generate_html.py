import os
import sys
from jinja2 import Environment, FileSystemLoader

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def main():
    # Ensure at least one city is provided
    if len(sys.argv) < 2:
        print("Usage: python generate_html.py city1 city2 city3 ...")
        sys.exit(1)

    # List of cities from command-line arguments
    cities = sys.argv[1:]

    # Load the template from the current directory
    env = Environment(loader=FileSystemLoader('./resources'))
    template = env.get_template('template.html')

    # Generate an HTML file for each city
    for city in cities:
        output_html = template.render(city=city)
        output_file = f"{city.replace(' ', '_').lower()}.html"  # Sanitize filename
        with open(os.path.join('./html', output_file), 'w', encoding='utf-8') as f:
            f.write(output_html)
        print(f"Generated {output_file}")


if __name__ == '__main__':
    main() 