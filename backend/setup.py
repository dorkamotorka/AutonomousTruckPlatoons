import setuptools
setuptools.setup(
    packages=['shortest_path', 'tcp_server'], # Here we should list all of our packages
    install_requires=[
        "selectors",
        "flask_cors",
        "flask",
    ], # Here list all of the project dependencies 
)
