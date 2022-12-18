from setuptools import setup
if __name__ == '__main__':
    setup(
        name="lodoo",
        install_requires=[
            "click; python_version >= '3.7'",
            "click<8.1; python_version < '3.7'",
            "click<8.0; python_version < '3.5'",
        ]
    )
