let
  python-packages = ps:
    with ps; [
      # Mathematical computations
      numba # Speed up Python computations
      numpy
      sympy # Symbolic mathematics
      scipy # Scientific computations

      # Data analysis
      pandas
      matplotlib # Data visualization
      seaborn # Statistical data visualization
      scikit-learn # Machine learning library

      # Image processing
      pillow # Image processing

      # Web development
      requests # HTTP requests
      flask # Web framework
      django # Web framework
      sqlalchemy # SQL toolkit and ORM
      beautifulsoup4 # Web scraping

      # Text processing
      ansi2image # Convert ANSI codes to images
      pygments # Syntax highlighting
      tiktoken # Fast tokenizer from OpenAI

      # GUI development
      tkinter

      # Utilities
      tqdm # Progress bars
      more-itertools # Additional functions for working with iterables

      # Testing
      pytest # Testing framework

      # Code formatting
      black # Code formatter

      # Static typing
      mypy # Static type checker
    ];
in
  python-packages
